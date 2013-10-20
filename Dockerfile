FROM mikz/passenger:1.9
ADD . /www
RUN bundle install --deployment --without test development
ENV RAILS_ENV production
EXPOSE 3000
ENTRYPOINT ["passenger", "start"]
