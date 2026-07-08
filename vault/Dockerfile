FROM openbao/openbao:latest

COPY ./ /bao/
# RUN bao policy write vcc-token "/bao/vcc_token_policy.hcl"
RUN chmod +x /bao/entrypoint.sh
ENTRYPOINT ["/bao/entrypoint.sh"]
