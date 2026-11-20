FROM tailscale/tailscale:stable AS tailscale

FROM madtomy/comfy-ui:v0.20.1

COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/tailscale
COPY --from=tailscale /usr/local/bin/tailscaled /usr/local/bin/tailscaled

COPY start.sh /opt/start-tailscale.sh
RUN chmod +x /opt/start-tailscale.sh

ENTRYPOINT ["/bin/bash", "/opt/start-tailscale.sh"]
