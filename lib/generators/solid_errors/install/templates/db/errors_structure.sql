SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: solid_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_errors (
    id bigint NOT NULL,
    exception_class text NOT NULL,
    message text NOT NULL,
    severity text NOT NULL,
    source text,
    resolved_at timestamp(6) without time zone,
    fingerprint character varying(64) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_errors_id_seq OWNED BY public.solid_errors.id;


--
-- Name: solid_errors_occurrences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_errors_occurrences (
    id bigint NOT NULL,
    error_id integer NOT NULL,
    backtrace text,
    context json,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_errors_occurrences_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_errors_occurrences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_errors_occurrences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_errors_occurrences_id_seq OWNED BY public.solid_errors_occurrences.id;


--
-- Name: solid_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_errors ALTER COLUMN id SET DEFAULT nextval('public.solid_errors_id_seq'::regclass);


--
-- Name: solid_errors_occurrences id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_errors_occurrences ALTER COLUMN id SET DEFAULT nextval('public.solid_errors_occurrences_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: solid_errors_occurrences solid_errors_occurrences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_errors_occurrences
    ADD CONSTRAINT solid_errors_occurrences_pkey PRIMARY KEY (id);


--
-- Name: solid_errors solid_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_errors
    ADD CONSTRAINT solid_errors_pkey PRIMARY KEY (id);


--
-- Name: index_solid_errors_occurrences_on_error_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_errors_occurrences_on_error_id ON public.solid_errors_occurrences USING btree (error_id);


--
-- Name: index_solid_errors_on_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_errors_on_fingerprint ON public.solid_errors USING btree (fingerprint);


--
-- Name: index_solid_errors_on_resolved_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_errors_on_resolved_at ON public.solid_errors USING btree (resolved_at);


--
-- Name: solid_errors_occurrences fk_rails_bab819a82b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_errors_occurrences
    ADD CONSTRAINT fk_rails_bab819a82b FOREIGN KEY (error_id) REFERENCES public.solid_errors(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('1');

