#!/bin/bash

cd test; julia --code-coverage=all runtests.jl
cd ..; julia codecoverage.jl
