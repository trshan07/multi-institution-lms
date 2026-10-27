"use client";

import { useEffect, useRef, useState, type FormEvent } from "react";
import {
  ArrowDownToLine,
  ArrowRight,
  Bell,
  BookOpen,
  CalendarDays,
  Check,
  ChevronLeft,
  ChevronRight,
  CircleHelp,
  Clock3,
  GraduationCap,
  LayoutDashboard,
  Menu,
  Plus,
  Search,
  Settings2,
  Sparkles,
  TrendingUp,
  Users,
  X,
  type LucideIcon,
} from "lucide-react";
import type { CourseCategory, CourseSummary } from "@lms/contracts";
import { events, initialCourses, people } from "../lib/demo-data";
import { LearningPulse } from "./learning-pulse";
import { WorkspaceSearch } from "./workspace-search";

type View = "Overview" | "Courses" | "People" | "Calendar" | "Settings";
const navigation: { label: View; icon: LucideIcon }[] = [
  { label: "Overview", icon: LayoutDashboard },
  { label: "Courses", icon: BookOpen },
  { label: "People", icon: Users },
  { label: "Calendar", icon: CalendarDays },
];
const storageKey = "aster-demo-courses-v1";

function CourseArt({ kind }: { kind: CourseSummary["artwork"] }) {
  return (
    <div className={`course-art ${kind}`} aria-hidden="true">
      <div className="art-grid" />
      <span className="art-orbit orbit-one" />
      <span className="art-orbit orbit-two" />
      <span className="art-block block-one" />
      <span className="art-block block-two" />
      <span className="art-block block-three" />
      <span className="art-caption">ASTER / LEARNING SERIES</span>
      <span className="art-number">
        {kind === "architecture"
          ? "01"
          : kind === "business"
            ? "02"
            : kind === "design"
              ? "03"
              : "04"}
      </span>
    </div>
  );
}

export function InstituteWorkspace() {
  const [view, setView] = useState<View>("Overview");
  const [courses, setCourses] = useState(initialCourses);
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("All courses");
  const [modal, setModal] = useState<"create" | "help" | null>(null);
  const [selected, setSelected] = useState<CourseSummary | null>(null);
  const [notifications, setNotifications] = useState(false);
  const [mobileNav, setMobileNav] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [notice, setNotice] = useState("");
  const [formError, setFormError] = useState("");
  const [institute, setInstitute] = useState("Aster Institute");
  const [savedName, setSavedName] = useState("Aster Institute");
  const dialogRef = useRef<HTMLDialogElement>(null);
  const sidebarRef = useRef<HTMLElement>(null);
  const menuButtonRef = useRef<HTMLButtonElement>(null);
  const showingModal = modal !== null || selected !== null;

  useEffect(() => {
    const media = window.matchMedia("(max-width: 700px)");
    function updateViewport() {
      setIsMobile(media.matches);
      if (!media.matches) setMobileNav(false);
    }
    updateViewport();
    media.addEventListener("change", updateViewport);
    return () => media.removeEventListener("change", updateViewport);
  }, []);

  useEffect(() => {
    if (!mobileNav || !isMobile) return;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    sidebarRef.current?.querySelector<HTMLButtonElement>(".nav-item.active")?.focus();
    function handleKey(event: KeyboardEvent) {
      if (document.querySelector("dialog[open]")) return;
      if (event.key === "Escape") {
        event.preventDefault();
        setMobileNav(false);
      }
      if (event.key !== "Tab") return;
      const items = sidebarRef.current?.querySelectorAll<HTMLElement>("a[href], button:not([disabled])");
      if (!items?.length) return;
      const first = items[0];
      const last = items[items.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault(); last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault(); first.focus();
      }
    }
    document.addEventListener("keydown", handleKey);
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", handleKey);
      if (window.matchMedia("(max-width: 700px)").matches && !document.querySelector("dialog[open]")) {
        menuButtonRef.current?.focus();
      }
    };
  }, [mobileNav, isMobile]);

  useEffect(() => {
    if (modal === "create") setFormError("");
  }, [modal]);

  useEffect(() => {
    try {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const parsed: unknown = JSON.parse(saved);
        if (
          Array.isArray(parsed) &&
          parsed.every(
            (c) =>
              c &&
              typeof c.id === "string" &&
              typeof c.title === "string" &&
              typeof c.code === "string" &&
              typeof c.instructor === "string" &&
              ["Technology", "Business", "Design"].includes(c.category) &&
              ["Published", "Draft"].includes(c.status) &&
              ["architecture", "business", "design", "data"].includes(
                c.artwork,
              ) &&
              typeof c.students === "number" &&
              typeof c.progress === "number",
          )
        )
          setCourses(parsed);
      }
      const name = localStorage.getItem("aster-demo-name");
      if (name) {
        setInstitute(name);
        setSavedName(name);
      }
    } catch {
      setNotice(
        "Browser storage is unavailable. Changes will last for this session.",
      );
    }
  }, []);

  useEffect(() => {
    if (showingModal) dialogRef.current?.showModal();
    else dialogRef.current?.close();
  }, [showingModal]);

  useEffect(() => {
    if (!notice) return;
    const timer = setTimeout(() => setNotice(""), 6000);
    return () => clearTimeout(timer);
  }, [notice]);

  function navigate(next: View) {
    setView(next);
    setQuery("");
    setMobileNav(false);
    setNotifications(false);
  }
  function closeModal() {
    setModal(null);
    setSelected(null);
  }
  function createCourse(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const title = String(data.get("title")).trim();
    const code = String(data.get("code")).trim().toUpperCase();
    const instructor = String(data.get("instructor")).trim();
    if (!title || !code || !instructor) {
      setFormError("Please complete all course fields.");
      return;
    }
    if (courses.some((c) => c.code.toUpperCase() === code)) {
      setFormError("A course with this code already exists.");
      return;
    }
    const next: CourseSummary[] = [
      ...courses,
      {
        id: crypto.randomUUID(),
        title,
        code,
        instructor,
        category: String(data.get("category")) as CourseCategory,
        students: 0,
        progress: 0,
        status: "Draft",
        artwork: "data",
      },
    ];
    setCourses(next);
    try {
      localStorage.setItem(storageKey, JSON.stringify(next));
      setNotice("Draft course created and saved in this browser.");
    } catch {
      setNotice(
        "Draft created for this session. Browser storage is unavailable.",
      );
    }
    closeModal();
    setView("Courses");
    setQuery("");
    setCategory("All courses");
  }
  function exportCourses() {
    // Quote fields and neutralize spreadsheet formula prefixes, including after whitespace.
    const cell = (value: string | number) =>
      '"' +
      String(value)
        .replace(/^\s*([=+@-])/, "'$1")
        .replaceAll('"', '""') +
      '"';
    const rows = [
      ["Code", "Course", "Category", "Instructor", "Students", "Status"],
      ...courses.map((c) => [
        c.code,
        c.title,
        c.category,
        c.instructor,
        c.students,
        c.status,
      ]),
    ];
    const url = URL.createObjectURL(
      new Blob([rows.map((row) => row.map(cell).join(",")).join("\r\n")], {
        type: "text/csv;charset=utf-8;",
      }),
    );
    const a = document.createElement("a");
    a.href = url;
    a.download = "aster-demo-courses.csv";
    a.click();
    URL.revokeObjectURL(url);
    setNotice("Course report downloaded.");
  }
  const visibleCourses = courses.filter(
    (c) =>
      (category === "All courses" || c.category === category) &&
      `${c.title} ${c.code} ${c.instructor}`
        .toLowerCase()
        .includes(query.toLowerCase()),
  );

  return (
    <div className="workspace">
      <a className="skip-link" href="#main">
        Skip to content
      </a>
      {mobileNav && (
        <button
          className="nav-scrim"
          aria-label="Close navigation"
          onClick={() => setMobileNav(false)}
        />
      )}
      <aside
        ref={sidebarRef}
        id="workspace-navigation"
        className={`sidebar ${mobileNav ? "is-open" : ""}`}
        inert={isMobile && !mobileNav}
        role={isMobile && mobileNav ? "dialog" : undefined}
        aria-modal={isMobile && mobileNav ? true : undefined}
        aria-label="Workspace navigation"
      >
        <button className="icon-button mobile-nav-close" aria-label="Close menu" onClick={() => setMobileNav(false)}><X size={20} /></button>
        <a className="brand" href="/" aria-label="Aster home">
          <span className="brand-symbol">
            <span className="brand-flower">✳</span>
          </span>
          <span>
            aster<span className="brand-dot">.</span>
          </span>
        </a>
        <div className="institution">
          <div className="institution-icon">
            <GraduationCap size={21} />
          </div>
          <div>
            <strong>{savedName}</strong>
            <span>INSTITUTE WORKSPACE</span>
          </div>
          <span className="institution-status" title="Demo workspace" />
        </div>
        <p className="nav-label">YOUR WORKSPACE</p>
        <nav aria-label="Main navigation">
          {navigation.map(({ label, icon: Icon }) => (
            <button
              key={label}
              onClick={() => navigate(label)}
              className={`nav-item ${view === label ? "active" : ""}`}
              aria-current={view === label ? "page" : undefined}
            >
              <Icon size={19} />
              <span>{label}</span>
              {label === "Courses" && (
                <span className="nav-count">
                  {courses.length.toString().padStart(2, "0")}
                </span>
              )}
            </button>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="semester-card">
            <span className="semester-icon">
              <Sparkles size={18} />
            </span>
            <p>A new chapter of learning.</p>
            <span>October semester, 2026</span>
            <div className="semester-line">
              <i />
            </div>
            <small>Week 6 of 16</small>
          </div>
          <button
            className={`nav-item ${view === "Settings" ? "active" : ""}`}
            onClick={() => navigate("Settings")}
          >
            <Settings2 size={18} />
            Institution settings
          </button>
          <button className="nav-item" onClick={() => { setMobileNav(false); setModal("help"); }}>
            <CircleHelp size={18} />
            Help & getting started
          </button>
          <div className="sidebar-footer">
            <span className="mini-logo">a.</span> A little structure. Endless
            possibility.
          </div>
        </div>
      </aside>
      <div className="main-shell" inert={isMobile && mobileNav}>
        <header className="topbar">
          <div className="breadcrumb">
            <button
              className="icon-button mobile-toggle"
              ref={menuButtonRef}
              aria-expanded={mobileNav}
              aria-controls="workspace-navigation"
              aria-label="Open navigation"
              onClick={() => setMobileNav(true)}
            >
              <Menu size={21} />
            </button>
            <span>Workspace</span>
            <ChevronRight size={14} />
            <strong>{view}</strong>
          </div>
          <WorkspaceSearch courses={courses} onSelect={setSelected} />
          <div className="topbar-actions">
            <span className="term">
              <span />
              2026 · Semester 02
            </span>
            <div className="notification-wrap">
              <button
                className={`icon-button ${notifications ? "pressed" : ""}`}
                aria-label="Notifications"
                aria-expanded={notifications}
                onClick={() => setNotifications(!notifications)}
              >
                <Bell size={19} />
                <i className="notification-dot" />
              </button>
              {notifications && (
                <div className="notification-panel">
                  <strong>Workspace updates</strong>
                  <p>Your demo workspace is ready.</p>
                  <small>Explore the courses or create your first draft.</small>
                  <button
                    onClick={() => {
                      setNotifications(false);
                      setModal("create");
                    }}
                  >
                    Create a course <ArrowRight size={15} />
                  </button>
                </div>
              )}
            </div>
            <div className="header-divider" />
            <div className="profile">
              <span className="avatar">AP</span>
              <div>
                <strong>Alex Perera</strong>
                <small>Institute administrator</small>
              </div>
            </div>
          </div>
        </header>
        <main id="main" tabIndex={-1}>
          <div className="page-heading">
            <div>
              <div className="eyebrow">
                {view === "Overview"
                  ? "THE BIG PICTURE"
                  : "ASTER / INSTITUTION WORKSPACE"}
              </div>
              <h1>
                {view === "Overview"
                  ? "Good things are growing."
                  : view === "Courses"
                    ? "Room for every ambition."
                    : view === "People"
                      ? "People make the difference."
                      : view === "Calendar"
                        ? "Make space for what’s next."
                        : "Make it your institution."}
              </h1>
              <p>
                {view === "Overview"
                  ? "Welcome back, Alex. Here’s what’s happening across your institute."
                  : view === "Courses"
                    ? "Curate learning experiences that move your students forward."
                    : view === "People"
                      ? "Meet the educators and learners in your community."
                      : view === "Calendar"
                        ? "A shared rhythm for teaching, learning, and coming together."
                        : "The details that make your learning community feel like home."}
              </p>
            </div>
            <button
              className="primary-button"
              onClick={() => setModal("create")}
            >
              <Plus size={18} />
              Create course
            </button>
          </div>
          <div className="demo-label">
            <span />
            Demo workspace <span className="demo-separator">/</span> Sample data
            · Your changes are saved in this browser
          </div>
          {view === "Overview" && (
            <>
              <section
                className="welcome-banner"
                aria-label="Semester overview"
              >
                <div className="banner-text">
                  <span className="banner-tag">
                    <span /> THE NEXT CHAPTER STARTS HERE
                  </span>
                  <h2>
                    A place to learn.
                    <br />A space to <em>become.</em>
                  </h2>
                  <p>
                    Big ideas. Small breakthroughs. Bring your entire learning
                    community together in one thoughtful space.
                  </p>
                  <button onClick={() => navigate("Courses")}>
                    Explore your courses <ArrowRight size={17} />
                  </button>
                  <div className="banner-community">
                    <span className="community-faces">
                      <i>MP</i>
                      <i>JF</i>
                      <i>AS</i>
                    </span>
                    <span>
                      Different minds. <strong>Shared possibilities.</strong>
                    </span>
                  </div>
                </div>
                <div className="hero-sculpture" aria-hidden="true">
                  <div className="orbit orbit-a" />
                  <div className="orbit orbit-b" />
                  <span className="hero-spark">✳</span>
                  <div className="sculpture-arch arch-back" />
                  <div className="sculpture-arch arch-front" />
                  <div className="sculpture-sphere" />
                  <div className="sculpture-step step-a" />
                  <div className="sculpture-step step-b" />
                  <div className="sculpture-step step-c" />
                  <span className="floating-note">
                    <BookOpen size={19} />
                    <span>
                      A little curiosity.
                      <br />
                      <strong>Endless possibility.</strong>
                    </span>
                  </span>
                  <span className="sculpture-caption">
                    LEARN / CONNECT / BECOME
                  </span>
                </div>
              </section>
              <section
                className="stats-grid"
                aria-label="Institution statistics"
              >
                {[
                  {
                    label: "Active learners",
                    value: "1,248",
                    change: "+12.8%",
                    note: "vs. last semester",
                    icon: Users,
                    color: "teal",
                  },
                  {
                    label: "Published courses",
                    value: String(
                      courses.filter((c) => c.status === "Published").length,
                    ).padStart(2, "0"),
                    change: `${courses.filter((c) => c.status === "Draft").length} draft`,
                    note: "ready to develop",
                    icon: BookOpen,
                    color: "blue",
                  },
                  {
                    label: "Teaching faculty",
                    value: "48",
                    change: "+4",
                    note: "this semester",
                    icon: GraduationCap,
                    color: "purple",
                  },
                  {
                    label: "Course completion",
                    value: "86.4%",
                    change: "+5.2%",
                    note: "vs. last semester",
                    icon: TrendingUp,
                    color: "gold",
                  },
                ].map((stat) => (
                  <article className="stat-card" key={stat.label}>
                    <div className="stat-top">
                      <span>{stat.label}</span>
                      <span className={`stat-icon ${stat.color}`}>
                        <stat.icon size={19} />
                      </span>
                    </div>
                    <strong>{stat.value}</strong>
                    <div className="stat-note">
                      <span>{stat.change}</span>
                      {stat.note}
                    </div>
                  </article>
                ))}
              </section>
              <div className="overview-columns">
                <section className="courses-section">
                  <div className="section-heading">
                    <div>
                      <h2>
                        Your courses{" "}
                        <span className="count-chip">{courses.length}</span>
                      </h2>
                      <p>Small steps. Meaningful progress.</p>
                    </div>
                    <button
                      className="text-button"
                      onClick={() => navigate("Courses")}
                    >
                      View all <ArrowRight size={15} />
                    </button>
                  </div>
                  <div className="course-grid">
                    {courses.slice(0, 3).map((course) => (
                      <CourseCard
                        key={course.id}
                        course={course}
                        onOpen={() => setSelected(course)}
                      />
                    ))}
                  </div>
                  <div className="learning-note">
                    <span>
                      <Sparkles size={17} /> Every course is a new possibility.
                    </span>
                    <button onClick={() => setModal("create")}>
                      Build something great <ArrowRight size={15} />
                    </button>
                  </div>
                </section>
                <section className="upcoming-section">
                  <div className="section-heading">
                    <h2>Coming up</h2>
                    <button
                      className="icon-button"
                      aria-label="View calendar"
                      onClick={() => navigate("Calendar")}
                    >
                      <ArrowRight size={18} />
                    </button>
                  </div>
                  <p className="section-subtitle">Keep your week in focus.</p>
                  <div className="event-list">
                    {events.map((event) => (
                      <div className="event" key={event.title}>
                        <div className={`event-date ${event.color}`}>
                          <strong>{event.day}</strong>
                          <span>{event.month}</span>
                        </div>
                        <div>
                          <span className={`event-category ${event.color}`}>
                            {event.category}
                          </span>
                          <h3>{event.title}</h3>
                          <p>
                            <Clock3 size={12} />
                            {event.time}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                  <button
                    className="calendar-button"
                    onClick={() => navigate("Calendar")}
                  >
                    Open calendar <ArrowRight size={15} />
                  </button>
                </section>
              </div>
              <div className="insights-row">
                <LearningPulse />
                <section className="community-panel">
                  <span className="eyebrow">BETTER, TOGETHER</span>
                  <h2>
                    Behind every milestone,
                    <br />
                    there’s a great educator.
                  </h2>
                  <p>
                    Make room for the people helping your community go further.
                  </p>
                  <div className="educator-list">
                    {people
                      .filter((person) => person.role === "Teacher")
                      .slice(0, 3)
                      .map((person) => (
                        <div key={person.email}>
                          <span className={`person-avatar ${person.color}`}>
                            {person.initials}
                          </span>
                          <span>
                            <strong>{person.name}</strong>
                            <small>{person.department}</small>
                          </span>
                          <GraduationCap size={18} />
                        </div>
                      ))}
                  </div>
                  <button
                    className="text-button"
                    onClick={() => navigate("People")}
                  >
                    Meet your community <ArrowRight size={17} />
                  </button>
                </section>
              </div>
              <section className="activity-strip">
                <div className="activity-icon">
                  <Check size={18} />
                </div>
                <div>
                  <strong>A little momentum goes a long way.</strong>
                  <p>
                    Your community is making time for learning, one activity at
                    a time. <span>Demo insight</span>
                  </p>
                </div>
                <span className="activity-bars" aria-hidden="true">
                  {[18, 28, 22, 36, 30, 43, 50, 42, 58, 65, 54, 72].map(
                    (height, index) => (
                      <i key={index} style={{ height: `${height}%` }} />
                    ),
                  )}
                </span>
              </section>
            </>
          )}
          {view === "Courses" && (
            <section className="catalog">
              <div className="catalog-toolbar">
                <div className="filter-tabs" aria-label="Filter courses">
                  {["All courses", "Technology", "Business", "Design"].map(
                    (item) => (
                      <button
                        key={item}
                        aria-pressed={category === item}
                        className={category === item ? "selected" : ""}
                        onClick={() => setCategory(item)}
                      >
                        {item}
                      </button>
                    ),
                  )}
                </div>
                <label className="search-field">
                  <Search size={17} />
                  <input
                    aria-label="Search courses"
                    placeholder="Search courses…"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                  />
                </label>
                <button className="secondary-button" onClick={exportCourses}>
                  <ArrowDownToLine size={16} />
                  Export
                </button>
              </div>
              <div className="catalog-caption">
                <span>{visibleCourses.length} courses in your workspace</span>
                <span>October semester · 2026</span>
              </div>
              <div className="course-grid catalog-grid">
                {visibleCourses.map((course) => (
                  <CourseCard
                    key={course.id}
                    course={course}
                    onOpen={() => setSelected(course)}
                  />
                ))}
              </div>
              {visibleCourses.length === 0 && (
                <div className="empty-state">
                  <Search size={28} />
                  <h2>No courses found</h2>
                  <p>Try another keyword or category.</p>
                  <button
                    className="secondary-button"
                    onClick={() => {
                      setQuery("");
                      setCategory("All courses");
                    }}
                  >
                    Clear filters
                  </button>
                </div>
              )}
            </section>
          )}
          {view === "People" && (
            <section className="panel">
              <div className="panel-heading">
                <h2>
                  Our community{" "}
                  <span className="count-chip">{people.length}</span>
                </h2>
                <label className="search-field">
                  <Search size={17} />
                  <input
                    aria-label="Search people"
                    placeholder="Search name or department…"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                  />
                </label>
              </div>
              <div className="table-scroll">
                <table>
                  <thead>
                    <tr>
                      <th>Name</th>
                      <th>Role</th>
                      <th>Department</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {people
                      .filter((person) =>
                        `${person.name} ${person.department} ${person.role}`
                          .toLowerCase()
                          .includes(query.toLowerCase()),
                      )
                      .map((person) => (
                        <tr key={person.email}>
                          <td>
                            <div className="person-cell">
                              <span className={`person-avatar ${person.color}`}>
                                {person.initials}
                              </span>
                              <div>
                                <strong>{person.name}</strong>
                                <small>{person.email}</small>
                              </div>
                            </div>
                          </td>
                          <td>{person.role}</td>
                          <td>{person.department}</td>
                          <td>
                            <span className="status-badge">Active</span>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
              {!people.some((p) =>
                `${p.name} ${p.department} ${p.role}`
                  .toLowerCase()
                  .includes(query.toLowerCase()),
              ) && (
                <div className="empty-state">No people match your search.</div>
              )}
              <p className="panel-footnote">
                Sample directory. Invitations and membership management will
                connect to the API in the next milestone.
              </p>
            </section>
          )}
          {view === "Calendar" && (
            <section className="calendar-layout">
              <div className="panel month-panel">
                <div className="panel-heading">
                  <h2>October 2026</h2>
                  <span className="count-chip">Semester 02</span>
                </div>
                <div className="month-grid">
                  {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map(
                    (day) => (
                      <strong className="day-label" key={day}>
                        {day}
                      </strong>
                    ),
                  )}
                  {Array.from({ length: 3 }, (_, i) => (
                    <div className="empty-day" key={`blank-${i}`} />
                  ))}
                  {Array.from({ length: 31 }, (_, i) => (
                    <div
                      className={`month-day ${i + 1 === 25 ? "today" : ""}`}
                      key={i}
                    >
                      <span>{i + 1}</span>
                      {events
                        .filter((e) => Number(e.day) === i + 1)
                        .map((e) => (
                          <span
                            className={`calendar-event ${e.color}`}
                            key={e.title}
                          >
                            {e.title}
                          </span>
                        ))}
                    </div>
                  ))}
                </div>
              </div>
              <div className="panel calendar-agenda">
                <h2>On the horizon</h2>
                <p>All times: Asia/Colombo</p>
                {events.map((e) => (
                  <div className="agenda-item" key={e.title}>
                    <span className="eyebrow">
                      OCTOBER {e.day} · {e.category}
                    </span>
                    <h3>{e.title}</h3>
                    <p>{e.time}</p>
                    <small>{e.location}</small>
                  </div>
                ))}
              </div>
            </section>
          )}
          {view === "Settings" && (
            <section className="panel settings-panel">
              <h2>Institution profile</h2>
              <p>A welcoming identity for your learning community.</p>
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  const name = institute.trim();
                  if (!name) return;
                  setSavedName(name);
                  try {
                    localStorage.setItem("aster-demo-name", name);
                    setNotice("Institution name saved in this browser.");
                  } catch {
                    setNotice("Name updated for this session only.");
                  }
                }}
              >
                <label>
                  Institution name
                  <input
                    required
                    maxLength={60}
                    value={institute}
                    onChange={(e) => setInstitute(e.target.value)}
                  />
                </label>
                <label>
                  Workspace domain
                  <input value="aster.example" disabled />
                </label>
                <p className="field-help">
                  Domain verification, branding uploads, and account permissions
                  will be available after backend integration.
                </p>
                <button className="primary-button" type="submit">
                  Save profile <Check size={16} />
                </button>
              </form>
            </section>
          )}
          <footer className="main-footer">
            <span>
              Thoughtfully connected. <strong>aster.</strong>
            </span>
            <span>{savedName} · Learning workspace</span>
          </footer>
        </main>
      </div>
      {notice && (
        <div className="toast" role="status">
          <Check size={18} />
          <span>{notice}</span>
          <button
            className="icon-button"
            aria-label="Dismiss notification"
            onClick={() => setNotice("")}
          >
            <X size={16} />
          </button>
        </div>
      )}
      <dialog
        ref={dialogRef}
        onCancel={closeModal}
        onClick={(e) => {
          if (e.target === e.currentTarget) closeModal();
        }}
        aria-labelledby="dialog-title"
      >
        <div className="dialog-content">
          <button
            className="icon-button close-dialog"
            aria-label="Close dialog"
            onClick={closeModal}
          >
            <X size={21} />
          </button>
          {modal === "create" ? (
            <>
              <span className="eyebrow">A NEW POSSIBILITY</span>
              <h2 id="dialog-title">Create a course</h2>
              <p>Start with the essentials. Your course begins as a draft.</p>
              <form onSubmit={createCourse}>
                {formError && (
                  <p className="form-error" role="alert">
                    {formError}
                  </p>
                )}
                <label>
                  Course title
                  <input
                    name="title"
                    required
                    maxLength={100}
                    placeholder="e.g. Introduction to Architecture"
                    autoFocus
                  />
                </label>
                <div className="form-row">
                  <label>
                    Course code
                    <input
                      name="code"
                      required
                      maxLength={16}
                      placeholder="ARC 101"
                    />
                  </label>
                  <label>
                    Department
                    <select name="category">
                      <option>Technology</option>
                      <option>Business</option>
                      <option>Design</option>
                    </select>
                  </label>
                </div>
                <label>
                  Instructor
                  <input
                    name="instructor"
                    required
                    maxLength={80}
                    placeholder="Instructor’s name"
                  />
                </label>
                <p className="field-help">
                  Demo mode: this draft is saved only in your current browser.
                </p>
                <div className="dialog-actions">
                  <button
                    type="button"
                    className="secondary-button"
                    onClick={closeModal}
                  >
                    Cancel
                  </button>
                  <button className="primary-button" type="submit">
                    <Plus size={16} />
                    Create draft
                  </button>
                </div>
              </form>
            </>
          ) : modal === "help" ? (
            <>
              <span className="eyebrow">WELCOME TO YOUR WORKSPACE</span>
              <h2 id="dialog-title">A little help getting started.</h2>
              <p>This is your institution’s first interactive prototype.</p>
              <ul className="help-list">
                <li>
                  <BookOpen size={20} />
                  <div>
                    <strong>Explore and create courses</strong>
                    <p>
                      Filter the catalog, view details, and save a draft in this
                      browser.
                    </p>
                  </div>
                </li>
                <li>
                  <Users size={20} />
                  <div>
                    <strong>Get to know the community</strong>
                    <p>
                      Search the sample directory by name, role, or department.
                    </p>
                  </div>
                </li>
                <li>
                  <Settings2 size={20} />
                  <div>
                    <strong>Make it yours</strong>
                    <p>
                      Update your institution’s display name under Settings.
                    </p>
                  </div>
                </li>
              </ul>
              <p className="field-help">
                Authentication, real enrollments, and server persistence are
                planned next. Use sample information here.
              </p>
            </>
          ) : (
            selected && (
              <>
                <CourseArt kind={selected.artwork} />
                <span className="eyebrow">
                  {selected.code} · {selected.category}
                </span>
                <h2 id="dialog-title">{selected.title}</h2>
                <p>Led by {selected.instructor}</p>
                <div className="detail-stats">
                  <div>
                    <strong>{selected.students}</strong>
                    <span>Enrolled learners</span>
                  </div>
                  <div>
                    <strong>{selected.progress}%</strong>
                    <span>Average progress</span>
                  </div>
                  <div>
                    <strong>{selected.status}</strong>
                    <span>Course status</span>
                  </div>
                </div>
                <p className="field-help">
                  Course overview preview. Content authoring, enrollment, and
                  assessments will be connected in the next development phase.
                </p>
                <button className="secondary-button" onClick={closeModal}>
                  <ChevronLeft size={16} />
                  Back to workspace
                </button>
              </>
            )
          )}
        </div>
      </dialog>
    </div>
  );
}

function CourseCard({
  course,
  onOpen,
}: {
  course: CourseSummary;
  onOpen: () => void;
}) {
  return (
    <button className="course-card" onClick={onOpen}>
      <CourseArt kind={course.artwork} />
      <div className="course-body">
        <div className="course-meta">
          <span>{course.category}</span>
          <span
            className={`course-status ${course.status === "Draft" ? "draft" : ""}`}
          >
            {course.status}
          </span>
        </div>
        <h3>{course.title}</h3>
        <p className="instructor">
          <span className="instructor-avatar">
            {course.instructor
              .replace("Dr. ", "")
              .split(" ")
              .map((n) => n[0])
              .slice(0, 2)
              .join("")}
          </span>
          {course.instructor}
        </p>
        <div className="course-divider" />
        <div className="course-progress-label">
          <span>
            <Users size={13} />
            {course.students} learners
          </span>
          <strong>{course.progress}%</strong>
        </div>
        <div className="progress-track">
          <i style={{ width: `${course.progress}%` }} />
        </div>
        <div className="course-bottom">
          <span>{course.code}</span>
          <ArrowRight size={15} />
        </div>
      </div>
    </button>
  );
}
