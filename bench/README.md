# Bench

Go into this directory and run one of the following benchmarks.

## General comparison

```bash
mix bench.xml_to_map
```

## Handler refactor comparison

```bash
mix bench.refactor_comparison
```

This benchmark compares the copied pre-refactor handler with the current
`SAXMap.Handler` using identical inputs. It verifies that both implementations
produce the same output before Benchee starts timing them.

