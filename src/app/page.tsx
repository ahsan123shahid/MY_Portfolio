import Navbar from '@/components/Navbar';
import ScrollySection from '@/components/ScrollySection';
import About from '@/components/About';
import Projects from '@/components/Projects';
import Process from '@/components/Process';
import Skills from '@/components/Skills';
import Experience from '@/components/Experience';
import Education from '@/components/Education';
import Testimonial from '@/components/Testimonial';
import ContactForm from '@/components/ContactForm';
import Footer from '@/components/Footer';
import WhatsAppButton from '@/components/WhatsAppButton';

export default function Home() {
  return (
    <main className="bg-[#0a0a0a]">
      <Navbar />
      <ScrollySection />
      <About />
      <Projects />
      <Process />
      <Skills />
      <Experience />
      <Education />
      <Testimonial />
      <ContactForm />
      <Footer />
      <WhatsAppButton />
    </main>
  );
}
