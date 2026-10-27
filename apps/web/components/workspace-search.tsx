"use client";

import { useEffect, useRef, useState } from "react";
import { ArrowUpRight, BookOpen, Search, X } from "lucide-react";
import type { CourseSummary } from "@lms/contracts";

export function WorkspaceSearch({
  courses,
  onSelect,
}: {
  courses: CourseSummary[];
  onSelect: (course: CourseSummary) => void;
}) {
  const [query, setQuery] = useState("");
  const dialog = useRef<HTMLDialogElement>(null);
  const input = useRef<HTMLInputElement>(null);
  function open() {
    setQuery("");
    dialog.current?.showModal();
    input.current?.focus();
  }
  useEffect(() => {
    function shortcut(event: KeyboardEvent) {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
        event.preventDefault();
        if (!document.querySelector('dialog[open], [aria-modal="true"]')) open();
      }
    }
    window.addEventListener("keydown", shortcut);
    return () => window.removeEventListener("keydown", shortcut);
  }, []);
  const matches = courses.filter((course) =>
    `${course.title} ${course.code} ${course.instructor}`
      .toLowerCase()
      .includes(query.toLowerCase()),
  );
  return (
    <>
      <button
        className="workspace-search"
        aria-label="Search workspace"
        onClick={open}
      >
        <Search size={17} />
        <span>Find a course, find your next idea…</span>
        <kbd>Ctrl K</kbd>
      </button>
      <dialog
        className="search-dialog"
        ref={dialog}
        aria-labelledby="search-title"
        onClick={(e) => {
          if (e.target === e.currentTarget) dialog.current?.close();
        }}
      >
        <div className="search-dialog-header">
          <Search size={22} />
          <h2 id="search-title">Search your workspace</h2>
          <button
            className="icon-button"
            aria-label="Close search"
            onClick={() => dialog.current?.close()}
          >
            <X size={20} />
          </button>
        </div>
        <label className="sr-only" htmlFor="workspace-query">
          Course title, code, or instructor
        </label>
        <input
          id="workspace-query"
          ref={input}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Course title, code, or instructor…"
        />
        <p className="search-results-label">
          {matches.length} COURSE{matches.length === 1 ? "" : "S"}
        </p>
        <div className="search-results">
          {matches.map((course) => (
            <button
              key={course.id}
              onClick={() => {
                dialog.current?.close();
                onSelect(course);
              }}
            >
              <span className="search-result-icon">
                <BookOpen size={18} />
              </span>
              <span>
                <strong>{course.title}</strong>
                <small>
                  {course.code} · {course.instructor}
                </small>
              </span>
              <ArrowUpRight size={18} />
            </button>
          ))}
          {matches.length === 0 && (
            <div className="empty-state">
              <Search size={24} />
              <h3>No matching courses</h3>
              <p>Try a different title, code, or instructor.</p>
            </div>
          )}
        </div>
        <div className="search-hint">
          <span>Discover something worth learning.</span>
          <span>
            <kbd>esc</kbd> to close
          </span>
        </div>
      </dialog>
    </>
  );
}
