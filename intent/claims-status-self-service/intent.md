# Intent: claims status self-service
Author: J. Ortiz (claims operations). Status: accepted.
## Problem
Customers keep phoning the contact center to ask where their claim is.
Handlers say status-only queries take about a third of their call time (handler estimate, not measured).
## Proposed outcome
Customers can see the status of their claim themselves in the portal.
In the first version (MVP) a status label is enough. Showing the next step and an expected date is out of scope for now.
Success is measured by the handler time spent on status-only queries.
## Affected users and systems
Customers, contact center handlers, claims operations, the customer portal and its existing login.
Only customers need access. Third-party loss adjusters and other non-customers do not.
The system that holds claim status is not yet identified.
## Constraints
No new personal data in the portal session.
Use the existing login only.
Customers must not see claim status until the source of claim status is identified. Until then the status view is not exposed to them.
## Open questions
Which system is the source of claim status, and who owns it and the portal?
What are the baseline and target for handler time on status-only queries? The current figure is a handler estimate only.
