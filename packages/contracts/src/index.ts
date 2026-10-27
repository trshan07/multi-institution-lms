export type CourseCategory = 'Technology' | 'Business' | 'Design';
export interface CourseSummary {
  id: string;
  title: string;
  code: string;
  category: CourseCategory;
  instructor: string;
  students: number;
  progress: number;
  status: 'Published' | 'Draft';
  artwork: 'architecture' | 'business' | 'design' | 'data';
}
export interface HealthResponse { status: 'ok'; service: string; }
