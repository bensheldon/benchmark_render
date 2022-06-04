# Rails Render Performance

Benchmarks Rails partial rendering and ViewComponents based on [discussion](https://github.com/rails/rails/issues/41452).

```shell
WITHOUT_LOGGER=1 RAILS_VERSION=6.0.5 ./benchmark_render.rb \
  && WITHOUT_LOGGER=1 RAILS_VERSION=7.0.3 ./benchmark_render.rb \
  && WITHOUT_LOGGER=1 ./benchmark_render.rb
```
