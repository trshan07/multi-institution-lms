import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Aster Institute · Learning, connected',
  description: 'An institution workspace for courses, people, and learning.'
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
