.PHONY: validate build-client genesis-tooling
validate:
	python3 scripts/validate-network.py
build-client:
	./scripts/bootstrap-upstream.sh
genesis-tooling:
	./scripts/prepare-genesis-tooling.sh
