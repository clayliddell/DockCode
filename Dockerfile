FROM docker/sandbox-templates:opencode

USER root

COPY opencode.example.json /home/agent/.config/opencode/opencode.json
RUN chown -R agent:agent /home/agent/.config/opencode

USER agent
