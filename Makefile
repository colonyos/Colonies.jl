all: build

github_test:
	./bin/colonies server start --serverid=039231c7644e04b6895471dd5335cf332681c54e27f81fac54f9067b3f2c0103 --port=50080 --dbhost localhost --dbport 5432 --dbuser postgres --dbpassword=rFcLGNkgsNtksg6Pgtn9CumL4xXBQ7 --insecure & sleep 3; ./bin/colonies database create --dbhost localhost --dbport 5432 --dbuser postgres --dbpassword=rFcLGNkgsNtksg6Pgtn9CumL4xXBQ7 & sleep 3; cd test; julia runtests.jl
