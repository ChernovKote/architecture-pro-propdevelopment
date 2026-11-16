# Задание 7. Аудит безопасности контейнеров Kubernetes

## 1. Реализованное решение

Для проверки безопасности контейнеров использованы два механизма:

- **Pod Security Admission (PSA)** — встроенный механизм Kubernetes с уровнем `restricted`.
- **OPA Gatekeeper** — дополнительный Admission Controller для проверки пользовательских политик безопасности.

Работа выполнена в Minikube (Kubernetes v1.37.0).

## 2. Pod Security Admission

Создан namespace `audit-zone` с метками:

```yaml
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
```

Проверены три небезопасных манифеста:

| Манифест | Нарушение | Результат |
|---|---|---|
| `01-privileged-pod.yaml` | `privileged: true` | Отклонён |
| `02-hostpath-pod.yaml` | Использование `hostPath` | Отклонён |
| `03-root-user-pod.yaml` | Запуск от UID 0 | Отклонён |

После исправления созданы три безопасных Pod. Все успешно запущены в namespace `audit-zone`.

## 3. OPA Gatekeeper

Установлен OPA Gatekeeper версии v3.23.1.

Настроены следующие ограничения:

| Constraint | Требование |
|---|---|
| `block-privileged` | Запрет `privileged: true` |
| `block-hostpath` | Запрет томов `hostPath` |
| `require-nonroot` | Обязательный запуск без root |
| `require-readonlyfs` | Обязательный `readOnlyRootFilesystem: true` |

Все ограничения работают в режиме `enforcementAction: deny`.

Проверки Gatekeeper выполнены отдельно в namespace `gatekeeper-test`, чтобы исключить влияние Pod Security Admission.

## 4. Инструкция по воспроизведению

### Создание namespace

```bash
kubectl apply -f Task7/01-create-namespace.yaml
```

### Установка Gatekeeper

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.23.1/deploy/gatekeeper.yaml
```

### Применение политик

Сначала создаются шаблоны ограничений:

```bash
kubectl apply -f Task7/gatekeeper/constraint-templates/
```

После регистрации шаблонов применяются сами ограничения:

```bash
kubectl apply -f Task7/gatekeeper/constraints/
```

### Проверка небезопасных манифестов

```bash
kubectl apply -f Task7/insecure-manifests/
```

Ожидаемый результат — три ошибки Forbidden

### Проверка безопасных манифестов

```bash
kubectl apply -f Task7/secure-manifests/
kubectl get pods -n audit-zone
```

Ожидаемый результат — три Pod в состоянии Running

## 5. Автоматизированная проверка

Для проверки подготовлены два скрипта.

**Проверка admission-контроллеров:**

```bash
bash Task7/verify/verify-admission.sh
```

**Проверка конфигурации PSA и Gatekeeper:**

```bash
bash Task7/verify/validate-security.sh
```

Оба скрипта успешно выполнены.

## 6. Аудит

В учебном Minikube ранее настроено журналирование Kubernetes API с использованием audit-policy.yaml.

Для аудита политики безопасности namespace установлен режим pod-security.kubernetes.io/audit=restricted.

## 7. Вывод

В результате настроена защита Kubernetes от развёртывания контейнеров с небезопасными параметрами.

Pod Security Admission обеспечивает стандартный набор ограничений, а OPA Gatekeeper позволяет дополнительно применять пользовательские правила.

Проверено, что небезопасные манифесты блокируются, а безопасные Pod успешно создаются и запускаются.

Решение является учебным. Политики Gatekeeper проверяют основные сценарии, указанные в задании, и могут быть расширены для проверки дополнительных типов контейнеров и рабочих нагрузок.