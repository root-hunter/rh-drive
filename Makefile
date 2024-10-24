start:
	rails server

db-recreate:
	rails db:drop db:create db:migrate