# Android acceptance coverage

Reference behavior and limits are documented separately. The demo uses the bundled fixtures and original UI copy throughout. [Reference audit](../reference-audit.md)

## Reference routes and checks

Evidence identifiers below refer to the Android integration suite, focused tests, and installed-build checks recorded in the [package handoff](package.md).

| ID | Entry and exercised outcome | Fixture | Evidence |
| --- | --- | --- | --- |
| R01 | Sign-in validates the phone format, switches language, and requests a local challenge. An unknown account and the first request in the recovery scenario produce errors. | standard, recoverable_error | Local auth, Foundation, installed APK |
| R02 | OTP shows a masked number and countdown. Tested wrong code, automatic confirmation, Back, resend timing and expiry. | standard | Local auth, Foundation |
| R03 | Home shows the one-time prompt. Not now continues and Enable delivers the local sample station alert. | standard | Foundation, Account, [native enable check](../step4_account_services/package.md#evidence-and-downstream-contract) |
| R04 | Home displays the company greeting and same balance/card data as Cards and Balances. It shows 48-hour activity and the inbox unread count. View all opens the inbox. | standard, quiet, large_fleet | Fixture substitution, Account, installed APK |
| R05 | Cards combines status and plate search. Stopped card shows missing activation. Exports use the visible card scope. | standard, large_fleet | Cards and finance, Large fleet, local export |
| R06 | Card details shows status, balance, card/plate, plan, fuel and available metadata. Details and Financial operations are both reachable. | standard | Cards and finance, installed APK |
| R07 | Add/edit/delete note uses per-card local state and validates the 500-character limit. A deleted seeded note stays deleted after cold restart. | standard | Local note tests, Cards and finance, installed APK |
| R08 | Card Details → Financial operations shows dated signed rows and opens the full card log. | standard | Cards and finance |
| R09 | The same per-card log is reachable from Cards and Balances. Type/date filtering scopes the rows. Android CSV and XLSX and cancellation are exercised with the Deposit filter. | standard | Local date tests, Cards and finance, installed APK |
| R10 | Balances displays the account total and per-card balances and dates, with the same Operations log and export formats. | standard, empty | Local finance tests, Cards and finance, installed APK |
| R11 | Stations combines search, city and fuel, restores criteria after Back, and shows status labels. Directions appears only for stations with a preview. | standard, empty | Stations and prices, installed APK |
| R12 | Station Details shows name, address, city and fuel availability. Directions opens a local sample route. | standard | Stations and prices, installed APK |
| R13 | Home and More reach the current bulletin and ordered history. Current and previous detail show the effective date and explicit product prices. | standard, empty | Stations and prices, installed APK |
| R14 | Sales from More and Home uses the shared route and displays receipt, card, product, station, dates and prices. Product/card/date filters constrain the export rows. | standard, empty | Cards and finance, local finance tests |
| R15 | More shows the company, contact, registration, city and card count. Each service links to its account or shared route. | standard | Account, Stations and prices, installed APK |
| R16 | Subscription includes the next date and per-card status. Invoice history includes paid and unpaid records and the exempt card has none. | standard, empty | Account, local subscription tests |
| R17 | Top-up displays an inert QR, copies the destination and a card-specific note, and offers native PNG save/share. The saved QR decodes to sample text. | standard | Account, [QR decode and share check](../step4_account_services/package.md#evidence-and-downstream-contract), installed APK |
| R18 | Important information expands an FAQ question to show its answer. | standard | Account |
| R19 | Notification settings enables a local station event once and persists the toggle. Read state and delivery survive a controller restart. | standard, quiet | Account, local inbox tests |
| R20 | Bell, More and Home View all all open the same inbox. Opening a linked alert updates unread state and opens the station. Quiet shows an empty inbox. | standard, quiet | Account, quiet widget test |
| R21 | Language switches from sign-in and More, updates direction immediately and persists on restart. | standard | Local routing test, Foundation, Account, installed APK |
| R22 | About displays Android package version and a synthetic support contact. | standard | Account, installed APK |
| R23 | Logout can be canceled or confirmed. Confirmation clears the session and Back cannot reopen protected routes. | standard | Account, local routing test, installed APK |
