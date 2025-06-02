use std::{error, fmt::Display, process};

use serde::Deserialize;
use rinja::Template;

#[derive(Deserialize)]
struct Social {
  site: Box<str>,
  profile: Box<str>,
}

#[derive(Deserialize)]
struct Contact {
  location: Box<str>,
  email: Box<str>,
  website: Box<str>,
  socials: Box<[Social]>,
}

#[derive(Deserialize)]
struct Education {
  institution: Box<str>,
  program: Box<str>,
  duration: Box<str>,
}

#[derive(Deserialize)]
struct SkillSet {
  subset: Box<str>,
  skills: Box<[Box<str>]>,
}

#[derive(Deserialize)]
struct Experience {
  organization: Box<str>,
  duration: Box<str>,
  position: Box<str>,
  descriptions: Box<[Box<str>]>,
}

#[derive(Deserialize)]
struct Award {
  event: Option<Box<str>>,
  prize: Box<str>,
  time: Box<str>,
  descriptions: Box<[Box<str>]>,
}

#[derive(Deserialize)]
struct Publication {
  title: Box<str>,
  published: Box<str>,
  link: Box<str>,
}

#[derive(Deserialize)]
struct Project {
  name: Box<str>,
  time: Box<str>,
  topics: Box<[Box<str>]>,
  descriptions: Box<[Box<str>]>,
}

#[derive(Deserialize)]
struct Resume {
  title: Box<str>,
  contact: Contact,
  education: Box<[Education]>,
  skills: Box<[SkillSet]>,
  experiences: Option<Box<[Experience]>>,
  awards: Option<Box<[Award]>>,
  publications: Option<Box<[Publication]>>,
  projects: Option<Box<[Project]>>,
}

#[derive(Template)]
#[template(path="resume.html")]
struct ResumeTemplate {
  resume: Resume, 
}

const fn handle_error<T, E>(msg: impl Display) -> impl FnOnce(E) -> T
where E: error::Error {
  return move |err: E| {
    eprintln!("ERROR: {msg}: {err}");
    process::exit(1);
  }
}

const fn handle_none<T>(msg: impl Display) -> impl FnOnce() -> T {
  return move || {
    eprintln!("ERROR: {msg}");
    process::exit(1);
  }
}

fn main() {
  use std::{env, fs};

  let mut args = env::args();

  args.next().expect("Failed to get program name");

  let input_file = args.next()
    .unwrap_or_else(handle_none("No input provided"));

  let resume_str = fs::read_to_string(&input_file)
    .unwrap_or_else(handle_error(format!("Failed to read `{input_file}`")));

  let resume: Resume = toml::de::from_str(&resume_str)
    .unwrap_or_else(handle_error("Failed to parse resume"));

  let template = ResumeTemplate { resume };

  match args.next() {
    None => {
      use std::io;
      let mut stdout = io::stdout();

      template.write_into(&mut stdout)
        .unwrap_or_else(handle_error("Failed to write resume to stdout"));
    },
    Some(output_path) => {
      let mut file = fs::File::create(&output_path)
        .unwrap_or_else(handle_error(format!("Failed to open `{output_path}`")));

      template.write_into(&mut file)
        .unwrap_or_else(handle_error(format!("Failed to write resume to `{output_path}`")));
    },
  };
}
