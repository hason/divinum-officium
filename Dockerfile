FROM public.ecr.aws/docker/library/alpine:latest AS gitinfo

RUN apk add git
COPY .git /build/
WORKDIR /build

# Write build info to be available at $url/buildinfo
RUN echo "{" > /build/buildinfo
RUN echo "  \"build-date\": \"`date +%s`\"," >> /build/buildinfo
RUN echo "  \"build-date-human\": \"`date`\"," >> /build/buildinfo
RUN echo "  \"commit\": \"`git rev-parse HEAD`\"," >> /build/buildinfo
RUN echo "  \"branch\": \"`git rev-parse --abbrev-ref HEAD`\"" >> /build/buildinfo
RUN echo "}" >> /build/buildinfo

# Final container
FROM public.ecr.aws/docker/library/perl:5.42-slim AS final

RUN cpanm -n Carton

# Copy app and dependencies
COPY cpanfile ./
RUN carton install

WORKDIR /var/www

# Expose port
EXPOSE 5000

# Start the app with Starman
CMD ["carton", "exec", "starman", "--workers", "2", "--port", "5000", "app.psgi"]

COPY --chown=www-data:www-data web /var/www/web

# Write build info to be available at $url/buildinfo
COPY --from=gitinfo /build/buildinfo /var/www/web/buildinfo

# Expose default port
EXPOSE 80
