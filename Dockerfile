FROM debian:latest

LABEL "name"="shellcheck"
LABEL "maintainer"="pataraco@gmail.com"
LABEL "version"="0.1.0"

LABEL "com.github.actions.name"="shellcheck"
LABEL "com.github.actions.description"="Run shell check on ALL shell files in the repository"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="black"

RUN apt update
RUN apt install -y shellcheck

COPY run-action.sh /run-action.sh
RUN chmod +x /run-action.sh

ENTRYPOINT ["/run-action.sh"]
