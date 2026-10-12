ENV ?= dev
TF  := tf

.PHONY: init plan apply fmt lint docs
init:  ; $(TF) init -backend-config=backend/$(ENV).hcl -reconfigure
plan:  ; $(TF) plan  -var-file=env/$(ENV).tfvars -out=.plan.$(ENV)
apply: ; $(TF) apply .plan.$(ENV)
fmt:   ; $(TF) fmt -recursive
lint:  ; pre-commit run -a
docs:  ; terraform-docs .
