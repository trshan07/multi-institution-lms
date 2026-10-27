import Link from "next/link";
import { ArrowUpRight, BookOpen, GraduationCap, Sprout } from "lucide-react";
import styles from "../../components/auth/auth.module.css";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className={styles.shell}>
      <a className="skip-link" href="#auth-content">
        Skip to form
      </a>
      <aside className={styles.story} aria-label="Welcome to Aster">
        <Link href="/login" className={styles.brand} aria-label="Aster login">
          <span aria-hidden="true">✳</span>aster
          <span className={styles.brandDot}>.</span>
        </Link>
        <div className={styles.storyBody}>
          <span className={styles.eyebrow}>
            <span /> A LITTLE CURIOSITY. ENDLESS POSSIBILITY.
          </span>
          <h2>
            Your next chapter
            <br /> starts with <em>you.</em>
          </h2>
          <p>
            A place for bright minds, big questions, and all the little
            breakthroughs along the way.
          </p>
          <div className={styles.art} aria-hidden="true">
            <div className={styles.orbit} />
            <div className={styles.orbitOuter} />
            <span className={styles.spark}>✳</span>
            <div className={styles.sun} />
            <div className={styles.archBack} />
            <div className={styles.archFront} />
            <div className={styles.steps} />
            <div className={styles.sphere} />
            <div className={styles.note}>
              <span>
                <BookOpen size={20} />
              </span>
              <div>
                A world of knowledge.<strong>A place to belong.</strong>
              </div>
            </div>
            <div className={styles.smallNote}>
              <Sprout size={20} />
              <span>Room to grow.</span>
            </div>
          </div>
          <div className={styles.storyBottom}>
            <span className={styles.roundIcon}>
              <GraduationCap size={22} />
            </span>
            <p>
              Built around learning.
              <br />
              <strong>Designed around people.</strong>
            </p>
            <span className={styles.edition}>
              THE ASTER WAY
              <br />
              LEARN · CONNECT · BECOME
            </span>
          </div>
        </div>
        <div className={styles.storyFooter}>
          <span>Thoughtfully connected.</span>
          <span>Since your very first step.</span>
        </div>
      </aside>
      <div className={styles.formSide}>
        <header className={styles.topbar}>
          <span>YOUR LEARNING JOURNEY</span>
          <Link href="/">
            Explore the demo <ArrowUpRight size={15} />
          </Link>
        </header>
        <main className={styles.content} id="auth-content">
          {children}
        </main>
        <footer className={styles.footer}>
          <span>© {2026} Aster. Made for possibility.</span>
          <span>Learning, connected.</span>
        </footer>
      </div>
    </div>
  );
}
