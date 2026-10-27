"use client";

import Link from "next/link";
import { useRef, useState, type FormEvent } from "react";
import {
  ArrowLeft,
  ArrowRight,
  Building2,
  Check,
  Eye,
  EyeOff,
  Info,
  KeyRound,
  LockKeyhole,
  Mail,
  UserRound,
} from "lucide-react";
import styles from "./auth.module.css";

type Mode = "login" | "register" | "forgot" | "reset";
const copy = {
  login: {
    eyebrow: "GOOD TO HAVE YOU HERE",
    title: "Welcome back.",
    description:
      "Your people. Your courses. Your next big idea. Sign in and pick up where you left off.",
    button: "Sign in",
    icon: LockKeyhole,
  },
  register: {
    eyebrow: "EVERY GREAT JOURNEY STARTS SOMEWHERE",
    title: "Make room for possibility.",
    description:
      "Create your account and take the first step into your learning community.",
    button: "Create account",
    icon: UserRound,
  },
  forgot: {
    eyebrow: "LET’S GET YOU BACK ON TRACK",
    title: "A little help getting in.",
    description:
      "Forgot your password? It happens. Enter the email address you use for your Aster account.",
    button: "Send reset link",
    icon: Mail,
  },
  reset: {
    eyebrow: "A FRESH START",
    title: "New password. New chapter.",
    description:
      "Choose a strong password that’s unique to you, and get ready to pick up your learning journey.",
    button: "Reset password",
    icon: KeyRound,
  },
};

function PasswordField({
  id,
  label,
  error,
  onChange,
  confirmation = false,
  login = false,
}: {
  id: string;
  label: string;
  error?: string;
  onChange?: (value: string) => void;
  confirmation?: boolean;
  login?: boolean;
}) {
  const [visible, setVisible] = useState(false);
  return (
    <div className={styles.field}>
      <label htmlFor={id}>{label}</label>
      <div className={`${styles.inputWrap} ${error ? styles.invalid : ""}`}>
        <LockKeyhole size={17} aria-hidden="true" />
        <input
          id={id}
          name={id}
          type={visible ? "text" : "password"}
          autoComplete={login ? "current-password" : "new-password"}
          placeholder={
            confirmation
              ? "Enter your password again"
              : login
                ? "Enter your password"
                : "Create a strong password"
          }
          required
          maxLength={128}
          aria-invalid={!!error}
          aria-describedby={
            error
              ? `${id}-error`
              : !login && !confirmation
                ? "password-guidance"
                : undefined
          }
          onChange={(e) => onChange?.(e.target.value)}
        />
        <button
          type="button"
          className={styles.eyeButton}
          aria-label={`${visible ? "Hide" : "Show"} ${label.toLowerCase()}`}
          aria-pressed={visible}
          onClick={() => setVisible(!visible)}
        >
          {visible ? <EyeOff size={17} /> : <Eye size={17} />}
        </button>
      </div>
      {error && (
        <p className={styles.fieldError} id={`${id}-error`}>
          {error}
        </p>
      )}
    </div>
  );
}

export function AuthForm({ mode }: { mode: Mode }) {
  const text = copy[mode];
  const Icon = text.icon;
  const form = useRef<HTMLFormElement>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [password, setPassword] = useState("");
  const [previewMessage, setPreviewMessage] = useState("");
  const newPassword = mode === "register" || mode === "reset";
  const checks = [
    password.length >= 12,
    /[a-z]/i.test(password) && /[^a-z]/i.test(password),
    new Set(password).size >= 8,
  ];
  const score = checks.filter(Boolean).length;

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPreviewMessage("");
    const values = new FormData(event.currentTarget);
    const next: Record<string, string> = {};
    if (mode === "register") {
      if (!String(values.get("name") || "").trim())
        next.name = "Please enter your full name.";
      if (!String(values.get("institution") || "").trim())
        next.institution = "Please enter your institution name.";
    }
    if (mode !== "reset") {
      const email = String(values.get("email") || "").trim();
      if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
        next.email = "Enter a valid email address.";
    }
    if (mode !== "forgot") {
      const entered = String(values.get("password") || "");
      if (!entered) next.password = "Please enter your password.";
      else if (newPassword && entered.length < 12)
        next.password = "Use at least 12 characters for your new password.";
      if (newPassword && String(values.get("confirmation") || "") !== entered)
        next.confirmation = "Your passwords don’t match.";
      else if (newPassword && !values.get("confirmation"))
        next.confirmation = "Please confirm your password.";
    }
    setErrors(next);
    const first = Object.keys(next)[0];
    if (first) {
      form.current
        ?.querySelector<HTMLInputElement>(`[name="${first}"]`)
        ?.focus();
      return;
    }
    // Presentation only: never send, log, persist, or pretend to authenticate credentials.
    setPreviewMessage(
      mode === "login"
        ? "The sign-in form is ready. Authentication isn’t connected yet, so you haven’t been signed in. You can explore the demo workspace instead."
        : mode === "register"
          ? "Your form is ready. Account registration isn’t connected yet; no account has been created."
          : mode === "forgot"
            ? "The recovery form is ready. Email delivery isn’t connected yet; no reset email has been sent."
            : "The reset form is ready. Secure reset links aren’t connected yet; your password hasn’t changed.",
    );
    form.current?.reset();
    setPassword("");
  }

  return (
    <div
      className={`${styles.formCard} ${mode === "register" ? styles.register : ""}`}
    >
      {(mode === "forgot" || mode === "reset") && (
        <Link href="/login" className={styles.backLink}>
          <ArrowLeft size={15} />
          Back to sign in
        </Link>
      )}
      <span className={styles.formIcon}>
        <Icon size={23} strokeWidth={1.6} />
      </span>
      <span className={styles.formEyebrow}>{text.eyebrow}</span>
      <h1>{text.title}</h1>
      <p className={styles.description}>{text.description}</p>
      <form ref={form} onSubmit={submit} noValidate className={styles.form}>
        {mode === "register" && (
          <div className={styles.nameRow}>
            <div className={styles.field}>
              <label htmlFor="name">Full name</label>
              <div
                className={`${styles.inputWrap} ${errors.name ? styles.invalid : ""}`}
              >
                <UserRound size={17} aria-hidden="true" />
                <input
                  id="name"
                  name="name"
                  autoComplete="name"
                  placeholder="Alex Perera"
                  required
                  maxLength={100}
                  aria-invalid={!!errors.name}
                  aria-describedby={errors.name ? "name-error" : undefined}
                />
              </div>
              {errors.name && (
                <p id="name-error" className={styles.fieldError}>
                  {errors.name}
                </p>
              )}
            </div>
            <div className={styles.field}>
              <label htmlFor="institution">Institution</label>
              <div
                className={`${styles.inputWrap} ${errors.institution ? styles.invalid : ""}`}
              >
                <Building2 size={17} aria-hidden="true" />
                <input
                  id="institution"
                  name="institution"
                  autoComplete="organization"
                  placeholder="Your institute"
                  required
                  maxLength={120}
                  aria-invalid={!!errors.institution}
                  aria-describedby={
                    errors.institution ? "institution-error" : undefined
                  }
                />
              </div>
              {errors.institution && (
                <p id="institution-error" className={styles.fieldError}>
                  {errors.institution}
                </p>
              )}
            </div>
          </div>
        )}
        {mode !== "reset" && (
          <div className={styles.field}>
            <label htmlFor="email">Email address</label>
            <div
              className={`${styles.inputWrap} ${errors.email ? styles.invalid : ""}`}
            >
              <Mail size={17} aria-hidden="true" />
              <input
                id="email"
                name="email"
                type="email"
                inputMode="email"
                autoComplete="email"
                placeholder="you@institute.edu"
                required
                maxLength={254}
                aria-invalid={!!errors.email}
                aria-describedby={errors.email ? "email-error" : undefined}
              />
            </div>
            {errors.email && (
              <p id="email-error" className={styles.fieldError}>
                {errors.email}
              </p>
            )}
          </div>
        )}
        {mode !== "forgot" && (
          <PasswordField
            id="password"
            label={newPassword ? "New password" : "Password"}
            error={errors.password}
            login={mode === "login"}
            onChange={setPassword}
          />
        )}
        {newPassword && (
          <div className={styles.passwordGuidance} id="password-guidance">
            <div className={styles.strengthBars} aria-hidden="true">
              {checks.map((_, index) => (
                <span
                  key={index}
                  className={password && index < score ? styles.filled : ""}
                />
              ))}
            </div>
            <span>
              {password
                ? score === 3
                  ? "Good length and variety"
                  : "Keep going — make it memorable and unique"
                : "At least 12 characters. A memorable passphrase works well."}
            </span>
          </div>
        )}
        {newPassword && (
          <PasswordField
            id="confirmation"
            label="Confirm password"
            error={errors.confirmation}
            confirmation
          />
        )}
        {mode === "login" && (
          <div className={styles.formOptions}>
            <span>
              <LockKeyhole size={12} />
              Your own space to learn
            </span>
            <Link href="/forgot-password">Forgot password?</Link>
          </div>
        )}
        {Object.keys(errors).length > 0 && (
          <p className={styles.errorSummary} role="alert">
            Please check the highlighted fields.
          </p>
        )}
        <button type="submit" className={styles.submitButton}>
          {text.button}
          <ArrowRight size={18} />
        </button>
        {previewMessage && (
          <div className={styles.notice} role="status">
            <Info size={18} />
            <p>{previewMessage}</p>
          </div>
        )}
      </form>
      {mode === "login" && (
        <p className={styles.switchPage}>
          New to Aster?{" "}
          <Link href="/register">
            Create an account <ArrowRight size={13} />
          </Link>
        </p>
      )}
      {mode === "register" && (
        <p className={styles.switchPage}>
          Already part of the community?{" "}
          <Link href="/login">
            Sign in <ArrowRight size={13} />
          </Link>
        </p>
      )}
      {mode === "forgot" && (
        <div className={styles.recoveryNote}>
          <Mail size={18} />
          <p>
            When recovery is connected, your reset link will arrive by email.{" "}
            <Link href="/reset-password">
              Preview the reset page <ArrowRight size={12} />
            </Link>
          </p>
        </div>
      )}
      {mode === "reset" && (
        <div className={styles.recoveryNote}>
          <Check size={18} />
          <p>
            Choose a password you haven’t used elsewhere. A real reset will
            require a valid, unexpired email link.
          </p>
        </div>
      )}
      <div className={styles.previewNote}>
        <span />
        Design preview · Authentication is not connected.
        <br />
        <span className={styles.previewDetail}>
          Use sample details. Credentials aren’t sent or stored.
        </span>
      </div>
    </div>
  );
}
