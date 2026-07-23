-- job radar — portfolio targeting migration
-- Run AFTER 01_schema.sql and 02_migration_auth.sql, in Project → SQL Editor → New query → Run.
-- Adds target_company + skill_targeted to portfolio_repos so a "build this" click
-- persists WHY a project exists, not just its title and repo URL. Both nullable —
-- repos created before this migration simply have no value for either.

alter table portfolio_repos add column if not exists target_company text;
alter table portfolio_repos add column if not exists skill_targeted text;
