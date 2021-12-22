alter table anon2020.active_storage_attachments add primary key (id) ;
alter table anon2020.active_storage_blobs add primary key (id) ;
alter table anon2020.anonymized_diy_intake_csv_extracts add primary key (id) ;
alter table anon2020.anonymized_intake_csv_extracts add primary key (id) ;
alter table anon2020.ar_internal_metadata add primary key (key) ;
alter table anon2020.clients add primary key (id) ;
alter table anon2020.delayed_jobs add primary key (id) ;
alter table anon2020.dependents add primary key (id) ;
alter table anon2020.diy_intakes add primary key (id) ;
alter table anon2020.documents add primary key (id) ;
alter table anon2020.documents_requests add primary key (id) ;
alter table anon2020.idme_users add primary key (id) ;
alter table anon2020.incoming_emails add primary key (id) ;
alter table anon2020.incoming_text_messages add primary key (id) ;
alter table anon2020.intake_site_drop_offs add primary key (id) ;
alter table anon2020.intakes add primary key (id) ;
alter table anon2020.notes add primary key (id) ;
alter table anon2020.outgoing_emails add primary key (id) ;
alter table anon2020.outgoing_text_messages add primary key (id) ;
alter table anon2020.provider_scrapes add primary key (id) ;
alter table anon2020.schema_migrations add primary key (version) ;
alter table anon2020.signups add primary key (id) ;
alter table anon2020.source_parameters add primary key (id) ;
alter table anon2020.spatial_ref_sys add primary key (srid) ;
alter table anon2020.states add primary key (abbreviation) ;
alter table anon2020.states_vita_partners add primary key (state_abbreviation, vita_partner_id) ;
alter table anon2020.stimulus_triages add primary key (id) ;
alter table anon2020.system_notes add primary key (id) ;
alter table anon2020.tax_returns add primary key (id) ;
alter table anon2020.ticket_statuses add primary key (id) ;
alter table anon2020.users add primary key (id) ;
alter table anon2020.users_vita_partners add primary key (user_id, vita_partner_id) ;
alter table anon2020.vita_partners add primary key (id) ;
alter table anon2020.vita_providers add primary key (id) ;
