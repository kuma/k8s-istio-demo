# 基本的な Go コマンド
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
ZIPKIN_POD_NAME=$(shell kubectl -n istio-system get pod -l app=zipkin -o jsonpath='{.items[0].metadata.name}')
JAEGER_POD_NAME=$(shell kubectl -n istio-system get pod -l app=jaeger -o jsonpath='{.items[0].metadata.name}')
SERVICEGRAPH_POD_NAME=$(shell kubectl -n istio-system get pod -l app=servicegraph -o jsonpath='{.items[0].metadata.name}')
GRAFANA_POD_NAME=$(shell kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}')
PROMETHEUS_POD_NAME=$(shell kubectl -n istio-system get pod -l app=prometheus -o jsonpath='{.items[0].metadata.name}')

# バイナリの名前
MAIN_BINARY_NAME=main
MAIN_BINARY_LINUX=$(MAIN_BINARY_NAME)_linux

all: test build
build-for-mac:
	$(GOBUILD) -o $(MAIN_BINARY_NAME) -v
build:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(MAIN_BINARY_LINUX) -v
test:
	$(GOTEST) -v ./...
clean:
	$(GOCLEAN)
	rm -f $(MAIN_BINARY_NAME)
	rm -f $(MAIN_BINARY_LINUX)
run:
	$(GOBUILD) -o $(MAIN_BINARY_NAME) -v ./...
	./$(MAIN_BINARY_NAME)
deps:
	$(GOGET) github.com/markbates/goth
	$(GOGET) github.com/markbates/pop
docker-build:
	make clean
	make build
	docker build -t kumasan/kubernetesdemo:0.3 .
docker-image:
	docker images
docker-run-local:
	docker run -it -p 4000:4000 kumasan/kubernetesdemo:0.3
docker-push:
	docker push kumasan/kubernetesdemo:0.3
kubernetes-run-standalone:
	kubectl create namespace demo
	kubectl run demo --image=docker.io/kumasan/kubernetesdemo:0.3 --namespace=demo
kubernetes-expose-standalone:
	kubectl expose deployment demo --target-port=4000 --port=80 --type=LoadBalancer --namespace=demo
kubernetes-clean-standalone:
	kubectl delete namespace demo
start-monitoring-services:
	$(shell kubectl -n istio-system port-forward $(SERVICEGRAPH_POD_NAME) 8088:8088 & kubectl -n istio-system port-forward $(GRAFANA_POD_NAME) 3000:3000 & kubectl -n istio-system port-forward $(PROMETHEUS_POD_NAME) 9090:9090))
kubernetes-run-prod:
	kubectl apply -f ./configs/kubernetes/deployments.yaml
	kubectl apply -f ./configs/kubernetes/services.yaml
kubernetes-create-virtualservice:
	istioctl create -f ./configs/istio/gateway.yaml
kubernetes-create-egress:
	istioctl create -f ./configs/istio/egress.yaml
kubernetes-clean-prod:
	kubectl delete -f ./configs/kubernetes/deployments.yaml
	kubectl delete -f ./configs/kubernetes/services.yaml
istio-get-gatewayip:
	kubectl get svc istio-ingressgateway -n istio-system
get-stuff:
	kubectl get pods && kubectl get svc && kubectl get ingress