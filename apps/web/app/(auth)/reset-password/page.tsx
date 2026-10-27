import type { Metadata } from "next";
import { AuthForm } from "../../../components/auth/auth-form";
export const metadata: Metadata = { title: "A fresh start · Aster" };
export default function ResetPasswordPage() {
  return <AuthForm mode="reset" />;
}
