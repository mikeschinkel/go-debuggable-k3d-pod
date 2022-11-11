
.force:

build:.force
	docker build -t debuggable-app-image .

debug: .force
	docker rm \
		debuggable-app-container 2>/dev/null || true
	docker create \
		--name debuggable-app-container \
		-p 8765:32345 \
		--security-opt="apparmor=unconfined" \
		--cap-add=SYS_PTRACE \
		debuggable-app-image
	docker start debuggable-app-container

deploy:
	docker image tag \
		debuggable-app-image \
		k3d-registry.localhost:5000/debuggable-app-image:latest
	docker image push \
		k3d-registry.localhost:5000/debuggable-app-image:latest
	make apply

apply:
	kubectl delete -f pod.yaml 2>/dev/null || true
	kubectl apply -f pod.yaml

