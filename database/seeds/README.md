# Seed policy

Migration `007_reference_data.sql` seeds seven activity-type contracts and twenty capability definitions. It does not create institutions, students, staff, plans, subscriptions, passwords, or demo academic records.

Tenant-specific default roles, role grants, settings, and institution contexts belong to the future idempotent provisioning transaction. There is intentionally no automatic tenant or admin account with default credentials. Database integrity tests create randomized temporary institutions and roll them back.
