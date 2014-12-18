# Flash

Flash is a 'command search engine' that makes it easy to quickly access urls
or api endpoints with a simple interface that can be shared between teams.


# Setup

Flash is targeted for an easy setup on Heroku, backed by Redis, and requires
Google OAuth (to make sure only employees with the correct email domain have
access to the search interface).

After launching a flash instance, it will walk you through configuration steps
to properly initialize (and protect) your instance.

You can launch a Flash instance for your own company easily with heroku:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

The instance works best when it is named _FlashYourCompanyName_.

#To Do List
1. Add integration tests `!important`
1. Move the entire application to a gem (easier to update instances)
1. Make the application mountable as a rails route
