Twitter Daily Archive
---------------------

Ever wanted to archive your Twitter timeline, but found it too complex?

With the program `archive.pl` you can store all of the tweets in your
timeline regularely to a local PostgreSQL database.

The program `list.pl` takes one parameter, a date, which is the date you want
to list tweets for.  It lists the tweets for the given day ordered by time
(oldest first).

Configuration setup
-------------------

You need to register an application with Twitter to use this program,
because it uses the OAuth Twitter API.  While you are logged into your
normal Twitter account you must visit <http://dev.twitter.com/> and follow the
registration procedure to get the consumer_key, consumer_secret,
access_token and access_token_secret.  Once you have those four values, you
need to create the file `$HOME/.twitter_daily_archive.ini` with the following
content:

    [twitter]
    consumer_key = <YOUR-CONSUMER-KEY>
    consumer_secret = <YOUR-CONSUMER-SECRET>
    access_token = <YOUR-ACCESS-TOKEN>
    access_token_secret = <YOUR-ACCESS-TOKEN-SECRET>

    [database]
    dsn = dbi:Pg:dbname=twitter_daily_archive
    username = <database-username>
    password = <database-password>

The entire `[database]` chunk is optional if you name your database
`twitter_daily_archive` and the local user has unauthenticated access to the
PostgreSQL instance running on localhost.

Database setup
--------------

As the user that is going to run the two scripts, run the following command
to create the database and import the schema:

    createdb -E UNICODE twitter_daily_archive
    psql -1 -f twitter_daily_archive.sql twitter_daily_archive

Crontab setup
-------------

To enable archiving of tweets and emailing you a bundle of tweets every day,
add the following to your crontab:

    # Archive tweets every hour
    0 * * * * ~/twitter_daily_archive/archive.pl
    # Email tweets 30 minutes past midnight every day (plain text)
    30 0 * * * ~/twitter_daily_archive/list.pl yesterday | mail -s 'Your Daily Tweets' your.email@here
    # Email tweets 30 minutes past midnight every day (in HTML)
    30 0 * * * ~/twitter_daily_archive/list.pl --html yesterday | mail -a 'Content-Type: text/html; charset=utf8' -s 'Your Daily Tweets' your.email@here

Copyright
---------

Robin Smidsrød <robin@smidsrod.no>

License
-------

This code is licensed according to the Artistic 2.0 license.

The full text of the license can be downloaded from
<http://www.opensource.org/licenses/Artistic-2.0>.
