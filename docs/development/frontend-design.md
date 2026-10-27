# Aster institute frontend

The first design pass is an institution workspace in `apps/web`. This is still the demo frontend; it does not use the new PostgreSQL tables yet. Student, teacher, and platform-operator experiences remain separate future workflows.

## Visual direction

Warm ivory surfaces (`#f7f8f3`), a pale navigation rail, forest green (`#244f3e`), and lime (`#d9ed93`) create a calm academic identity. Manrope and DM Sans support the interface; a serif headline and original CSS arches make the overview distinct. Fonts have system fallbacks. Course illustrations and the hero are local CSS, with no third-party image dependencies.

`app/workspace-base.css` contains shared component behavior, responsive foundations, and course illustrations. `app/globals.css` supplies the current institute theme and new components. Styling is separated from interaction logic; the activity chart and workspace search are dedicated React components.

## Implemented screens and interactions

- Overview: institute summary, sculptural welcome banner, course previews, upcoming events, sample activity chart, and faculty introduction.
- Courses: category filters, search, draft creation with visible validation, browser persistence, course detail dialog, and CSV export.
- People: searchable sample directory.
- Calendar: October 2026 demonstration calendar and event agenda.
- Settings: browser-persisted institution display name.
- Workspace search: header action or Ctrl/Cmd+K, title/code/instructor matches, and direct course-detail opening. Native dialogs support Escape and focus containment.
- Learning pulse: week/month sample datasets, keyboard-focusable values, and an accessible text description of chart data.

On small phones, course previews form a horizontally scrollable rail while the full catalog uses full-width cards. Other layouts adapt from 320px to desktop. Reduced-motion preferences suppress transitions. Closed mobile navigation is inert; the open menu contains keyboard focus, disables background interaction, locks page scrolling, and closes with Escape. Closing returns focus to its trigger. Resizing to desktop clears the mobile-menu state. Dialogs, form fields, and controls have accessible names. Formal accessibility certification and screen-reader review remain future checks.

## Verification

Chrome checks cover course creation and duplicate-code errors, persistence, filters, empty states, detail dialogs, CSV downloads, people search, calendar, settings, search shortcuts, chart periods, and responsive page widths. Development screenshots and test scripts are in ignored `.local/`. Use the root type-check and build commands for compile validation.
