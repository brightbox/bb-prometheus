id := $(shell id -u):$(shell id -g)
docker_run := docker run --rm -u $(id) -v $(CURDIR):$(CURDIR) --workdir $(CURDIR) quay.io/coreos/jsonnet-ci

build: manifests
manifests: vendor alertmanager-config.yaml
	$(docker_run) ./build.sh
apply: manifests
	kubectl apply -f $<
vendor: jsonnetfile.lock.json
	$(docker_run) jb install
jsonnetfile.json:
	$(docker_run) jb init
jsonnetfile.lock.json: jsonnetfile.json
	$(docker_run) jb install github.com/coreos/kube-prometheus/jsonnet/kube-prometheus
alertmanager-config.yaml: alertmanager-config.yaml.src
	test -n "$(SMTP_AUTH_USERNAME)" # $$SMTP_AUTH_USERNAME not set
	test -n "$(SMTP_AUTH_SECRET)" # $$SMTP_AUTH_SECRET not set
	test -n "$(TARGET_EMAIL)" # $$TARGET_EMAIL not set
	sed -e 's/SMTP_AUTH_USERNAME/$(SMTP_AUTH_USERNAME)/' \
	    -e 's/SMTP_AUTH_SECRET/$(SMTP_AUTH_SECRET)/' \
	    -e 's/TARGET_EMAIL/$(TARGET_EMAIL)/' $< > $@
update: jsonnetfile.lock.json
	$(docker_run) jb update
clean: 
	-rm -rf alertmanager-config.yaml manifests vendor
reallyclean: clean
	-rm -f jsonnetfile.json jsonnetfile.lock.json
%.json : %.yaml
	ruby -rjson -ryaml -e "puts JSON.pretty_generate(YAML.load(ARGF.read))" $< > $@
.PHONY:	build update apply clean reallyclean
.DELETE_ON_ERROR:
