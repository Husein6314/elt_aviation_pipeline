CREATE SCHEMA IF NOT EXISTS "raw";
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS "raw".flights (
    flight_date     VARCHAR(65535),
    flight_status   VARCHAR(65535),
    departure       VARCHAR(65535),
    arrival         VARCHAR(65535),
    airline         VARCHAR(65535),
    flight          VARCHAR(65535),
    aircraft        VARCHAR(65535),
    live            VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".airlines (
    id                      VARCHAR(65535),
    fleet_average_age       VARCHAR(65535),
    airline_id              VARCHAR(65535),
    callsign                VARCHAR(65535),
    hub_code                VARCHAR(65535),
    iata_code               VARCHAR(65535),
    icao_code               VARCHAR(65535),
    country_iso2            VARCHAR(65535),
    date_founded            VARCHAR(65535),
    iata_prefix_accounting  VARCHAR(65535),
    airline_name            VARCHAR(65535),
    country_name            VARCHAR(65535),
    fleet_size              VARCHAR(65535),
    status                  VARCHAR(65535),
    type                    VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".airplanes (
    id                          VARCHAR(65535),
    iata_type                   VARCHAR(65535),
    airplane_id                 VARCHAR(65535),
    airline_iata_code           VARCHAR(65535),
    iata_code_long              VARCHAR(65535),
    iata_code_short             VARCHAR(65535),
    airline_icao_code           VARCHAR(65535),
    construction_number         VARCHAR(65535),
    delivery_date               VARCHAR(65535),
    engines_count               VARCHAR(65535),
    engines_type                VARCHAR(65535),
    first_flight_date           VARCHAR(65535),
    icao_code_hex               VARCHAR(65535),
    line_number                 VARCHAR(65535),
    model_code                  VARCHAR(65535),
    registration_number         VARCHAR(65535),
    test_registration_number    VARCHAR(65535),
    plane_age                   VARCHAR(65535),
    plane_class                 VARCHAR(65535),
    model_name                  VARCHAR(65535),
    plane_owner                 VARCHAR(65535),
    plane_series                VARCHAR(65535),
    plane_status                VARCHAR(65535),
    production_line             VARCHAR(65535),
    registration_date           VARCHAR(65535),
    rollout_date                VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".airports (
    id              VARCHAR(65535),
    gmt             VARCHAR(65535),
    airport_id      VARCHAR(65535),
    iata_code       VARCHAR(65535),
    city_iata_code  VARCHAR(65535),
    icao_code       VARCHAR(65535),
    country_iso2    VARCHAR(65535),
    geoname_id      VARCHAR(65535),
    latitude        VARCHAR(65535),
    longitude       VARCHAR(65535),
    airport_name    VARCHAR(65535),
    country_name    VARCHAR(65535),
    phone_number    VARCHAR(65535),
    timezone        VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".cities (
    id              VARCHAR(65535),
    gmt             VARCHAR(65535),
    city_id         VARCHAR(65535),
    iata_code       VARCHAR(65535),
    country_iso2    VARCHAR(65535),
    geoname_id      VARCHAR(65535),
    latitude        VARCHAR(65535),
    longitude       VARCHAR(65535),
    city_name       VARCHAR(65535),
    timezone        VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".countries (
    id                  VARCHAR(65535),
    capital             VARCHAR(65535),
    currency_code       VARCHAR(65535),
    fips_code           VARCHAR(65535),
    country_iso2        VARCHAR(65535),
    country_iso3        VARCHAR(65535),
    continent           VARCHAR(65535),
    country_id          VARCHAR(65535),
    country_name        VARCHAR(65535),
    currency_name       VARCHAR(65535),
    country_iso_numeric VARCHAR(65535),
    phone_prefix        VARCHAR(65535),
    population          VARCHAR(65535)
);

CREATE TABLE IF NOT EXISTS "raw".taxes (
    id          VARCHAR(65535),
    tax_id      VARCHAR(65535),
    tax_name    VARCHAR(65535),
    iata_code   VARCHAR(65535)
);
