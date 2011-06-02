--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: subscriber; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE subscriber (
    subscriber_id bigint NOT NULL,
    username text NOT NULL,
    subscriber text NOT NULL,
    access_token text NOT NULL,
    access_token_secret text NOT NULL
);


--
-- Name: COLUMN subscriber.subscriber_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN subscriber.subscriber_id IS 'The id field of the raw verify_credentials data';


--
-- Name: COLUMN subscriber.username; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN subscriber.username IS 'The Twitter username from the raw JSON data';


--
-- Name: COLUMN subscriber.subscriber; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN subscriber.subscriber IS 'The raw JSON data associated with a subscriber from verify_credentials';


--
-- Name: COLUMN subscriber.access_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN subscriber.access_token IS 'The access_token required to access Twitter OAuth API';


--
-- Name: COLUMN subscriber.access_token_secret; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN subscriber.access_token_secret IS 'The access_token_secret required to access Twitter OAuth API';


--
-- Name: timeline; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE timeline (
    subscriber_id bigint NOT NULL,
    tweet_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp(0) with time zone NOT NULL
);


--
-- Name: TABLE timeline; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE timeline IS 'The exact time a user had a tweet posted on a subscriber''s timeline';


--
-- Name: tweet; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tweet (
    tweet_id bigint NOT NULL,
    tweet text NOT NULL
);


--
-- Name: COLUMN tweet.tweet_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tweet.tweet_id IS 'The id field from the raw JSON tweet data';


--
-- Name: COLUMN tweet.tweet; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN tweet.tweet IS 'The raw JSON tweet data';


--
-- Name: user; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE "user" (
    user_id bigint NOT NULL,
    "user" text NOT NULL
);


--
-- Name: COLUMN "user".user_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "user".user_id IS 'The id field from the raw JSON data for a user';


--
-- Name: COLUMN "user"."user"; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN "user"."user" IS 'The raw JSON data for a user';


--
-- Name: subscriber_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriber
    ADD CONSTRAINT subscriber_pkey PRIMARY KEY (subscriber_id);


--
-- Name: subscriber_username_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY subscriber
    ADD CONSTRAINT subscriber_username_key UNIQUE (username);


--
-- Name: timeline_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY timeline
    ADD CONSTRAINT timeline_pkey PRIMARY KEY (subscriber_id, tweet_id, user_id);


--
-- Name: tweet_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tweet
    ADD CONSTRAINT tweet_pkey PRIMARY KEY (tweet_id);


--
-- Name: user_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- Name: timeline_idx_created_at; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX timeline_idx_created_at ON timeline USING btree (created_at);


--
-- Name: timeline_idx_subscriber_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX timeline_idx_subscriber_id ON timeline USING btree (subscriber_id);


--
-- Name: timeline_idx_tweet_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX timeline_idx_tweet_id ON timeline USING btree (tweet_id);


--
-- PostgreSQL database dump complete
--

