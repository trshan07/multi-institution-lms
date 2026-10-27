import type { CourseSummary } from '@lms/contracts';

export const initialCourses: CourseSummary[] = [
  { id: 'cs101', title: 'Introduction to Computer Science', code: 'CS 101', category: 'Technology', instructor: 'Dr. Maya Perera', students: 128, progress: 68, status: 'Published', artwork: 'architecture' },
  { id: 'bus204', title: 'Business Strategy & Innovation', code: 'BUS 204', category: 'Business', instructor: 'James Fernando', students: 86, progress: 42, status: 'Published', artwork: 'business' },
  { id: 'des110', title: 'Foundations of Visual Design', code: 'DES 110', category: 'Design', instructor: 'Amelia Silva', students: 64, progress: 81, status: 'Published', artwork: 'design' },
  { id: 'ds201', title: 'Data Analytics Essentials', code: 'DS 201', category: 'Technology', instructor: 'Dr. Noah Wijesinghe', students: 92, progress: 24, status: 'Draft', artwork: 'data' },
];

export const people = [
  { name: 'Maya Perera', initials: 'MP', email: 'maya@aster.example', role: 'Teacher', department: 'Computing', color: 'teal' },
  { name: 'James Fernando', initials: 'JF', email: 'james@aster.example', role: 'Teacher', department: 'Business', color: 'gold' },
  { name: 'Amelia Silva', initials: 'AS', email: 'amelia@aster.example', role: 'Teacher', department: 'Design', color: 'purple' },
  { name: 'Noah Wijesinghe', initials: 'NW', email: 'noah@aster.example', role: 'Teacher', department: 'Computing', color: 'blue' },
  { name: 'Anika Jayawardena', initials: 'AJ', email: 'anika@aster.example', role: 'Student', department: 'Computing', color: 'purple' },
  { name: 'Ravi De Silva', initials: 'RS', email: 'ravi@aster.example', role: 'Student', department: 'Business', color: 'teal' },
];

export const events = [
  { day: '26', month: 'OCT', title: 'Faculty planning session', time: '09:00–10:00', location: 'Conference room A', category: 'Faculty', color: 'teal' },
  { day: '27', month: 'OCT', title: 'Design thinking workshop', time: '13:30–15:00', location: 'Creative studio', category: 'Workshop', color: 'purple' },
  { day: '29', month: 'OCT', title: 'Mid-semester submissions', time: 'Due at 23:59', location: 'All departments', category: 'Deadline', color: 'gold' },
];
