PROFILE = pronuri

STG = pronuri-docker-staging
PROD = pronuri-docker-production

ALL: install
setup-aws:
	pip3 install --upgrade awscli
	aws configure --profile $(PROFILE)
setup-awseb:
	pip3 install --upgrade awsebcli 
	eb init --profile $(PROFILE)
install:
	docker-compose -f docker-compose-dev.yml build
	docker-compose -f docker-compose-dev.yml run --rm web php composer.phar install
	cp .env.example .env
	docker-compose -f docker-compose-dev.yml exec web php artisan key:generate
	yarn
migrate:
	docker-compose -f docker-compose-dev.yml exec web php artisan migrate
rollback:
	docker-compose -f docker-compose-dev.yml exec web php artisan migrate:rollback
autoload:
	docker-compose -f docker-compose-dev.yml exec web composer dump-autoload
seed:
	docker-compose -f docker-compose-dev.yml exec web php artisan migrate:refresh --seed
create-qr:
	docker-compose -f docker-compose-dev.yml exec web php artisan db:seed --class=QrTableSeeder
create-c:
	docker-compose -f docker-compose-dev.yml exec web php artisan db:seed --class=CompanyTableSeeder
console:
	docker-compose -f docker-compose-dev.yml exec web php artisan tinker
clear:
	docker-compose -f docker-compose-dev.yml exec web php artisan cache:clear
	docker-compose -f docker-compose-dev.yml exec web php artisan route:cache
build:
	docker-compose -f docker-compose-dev.yml build
up:
	docker-compose -f docker-compose-dev.yml up -d
	@echo "[web]   http://localhost:8890"
	@echo "[email] http://localhost:1090"
	@echo "[db]    http://localhost:3390"
stop:
	docker-compose -f docker-compose-dev.yml stop
bash:
	docker-compose -f docker-compose-dev.yml exec web bash
ps:
	docker-compose -f docker-compose-dev.yml ps
prod:
	yarn prod
watch:
	yarn watch
deploy-stg:
	docker build -t 555969652412.dkr.ecr.ap-northeast-1.amazonaws.com/pronuri-docker:staging -f docker/DockerStg .
	`aws ecr get-login --profile $(PROFILE) --region ap-northeast-1 --no-include-email`
	docker push 555969652412.dkr.ecr.ap-northeast-1.amazonaws.com/pronuri-docker:staging
	eb deploy --profile $(PROFILE) $(STG)
deploy-prod:
	docker build -t 555969652412.dkr.ecr.ap-northeast-1.amazonaws.com/pronuri-docker:production -f docker/DockerProd .
	`aws ecr get-login --profile $(PROFILE) --region ap-northeast-1 --no-include-email`
	docker push 555969652412.dkr.ecr.ap-northeast-1.amazonaws.com/pronuri-docker:production
	cp Dockerrun.aws.prod.json Dockerrun.aws.json
	git add Dockerrun.aws.json && git commit -m 'deploy production' || echo "No changes to commit"
	eb deploy --profile $(PROFILE) $(PROD)
	git reset --hard HEAD~1
ssh-stg:
	eb ssh --profile $(PROFILE) $(STG)
ssh-prod:
	eb ssh --profile $(PROFILE) $(PROD)
ssh-stg-setup:
	eb ssh --setup --profile $(PROFILE) $(STG)
ssh-prod-setup:
	eb ssh --setup --profile $(PROFILE) $(PROD)
deploy-batch:
	docker-compose -f docker-compose-dev.yml run web php vendor/bin/dep deploy batch
deploy-stg-vn:
	ssh zigexn@192.168.1.68 -- "cd projects/pronuri && git pull && \
	    docker-compose -f docker-compose-dev.yml exec -T web php artisan cache:clear && \
	    docker-compose -f docker-compose-dev.yml exec -T web php artisan config:clear"
