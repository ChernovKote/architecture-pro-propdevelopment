# Отчёт по результатам анализа Kubernetes Audit Log

## Подозрительные события

1. Доступ к секретам

- Кто: minikube-user с использованием impersonation system:serviceaccount:secure-ops:monitoring.
- Где: namespace kube-system.
- Почему подозрительно: ServiceAccount monitoring попытались использовать для доступа к секретам системного namespace. RBAC успешно заблокировал запрос.

2. Создание привилегированного Pod

- Кто: minikube-user.
- Комментарий: создание privileged-pod с параметром securityContext.privileged: true в namespace secure-ops привилегированный контейнер получает расширенные возможности взаимодействия с операционной системой узла, что увеличивает риск компрометации инфраструктуры.

3. Использование kubectl exec в чужом Pod

- Кто: minikube-user.
- Что делал: попытка выполнить "cat /etc/resolv.conf" внутри Pod CoreDNS в namespace kube-system.

4. Создание RoleBinding с правами cluster-admin

- Кто: minikube-user.
- К чему привело: ServiceAccount получил широкие права в namespace secure-ops, включая чтение Secret. Проверка подтвердила, что доступ к Secret в kube-system отсутствует.

5. Удаление audit-policy.yaml

- Кто: не установлен.
- Комментарий: удаление политики аудита не моделировалось. Файл audit-policy.yaml является конфигурацией API Server, а не Kubernetes-ресурсом. Команда "kubectl delete -f" не предназначена для удаления таких файлов.


## Вывод

В результате анализа Kubernetes Audit Log выявлены попытка несанкционированного доступа к Secret, создание привилегированного Pod, использование "kubectl exec" в системном Pod и выдача избыточных прав ServiceAccount.

RBAC успешно заблокировал доступ к Secret в "kube-system", однако привилегированная учётная запись смогла выполнить потенциально опасные административные действия.
