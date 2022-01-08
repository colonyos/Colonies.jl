all: build

github_test:
	./bin/colonies server start --serverid=9289dfccedf27392810b96968535530bb69f90afe7c35738e0e627f3810d943e --port=8080 --tlscert=./cert/cert.pem --tlskey=./cert/key.pem --dbhost localhost --dbport 5432 --dbuser postgres --dbpassword=rFcLGNkgsNtksg6Pgtn9CumL4xXBQ7 & sleep 3; cd test; julia runtests.jl
