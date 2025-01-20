# Resumerator

A quick web-based resume/CV builder. It generates an HTML/CSS document from
structured data in TOML format.

## Why?

This project was created because I want to quickly adjust my resumes when there
are updates or when I want to apply to a different position. I also want to
store my resumes in a human-readable, plain-text format for various reasons
such as version control and ease of editing.

I decided to use the TOML format to store my resume and create a program that
converts that data into a document. HTML/CSS was used as the document format
because:

- It's easy to write code that generates HTML
- I'm familiar with CSS, so I have lots of flexibility and control
- You can print an HTML document into a PDF file

I tried to make this program as general as possible, so other people can use
it. But in its current state, it's mostly hard-coded for my usage.

## Running

Create an HTML document from a TOML resume data

```sh
cargo run --release resume.toml resume.html
```

Print the HTML document into a PDF file (this example uses Chromium)

```sh
chromium --headless --print-to-pdf=resume.pdf resume.html
```

# License

This app is licensed under the [MIT license](LICENSE).
