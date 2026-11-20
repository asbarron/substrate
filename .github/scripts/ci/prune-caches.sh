#!/usr/bin/env bash

# Copyright 2026 The Agent Substrate Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Deletes every Actions cache on REF whose key starts with one of the given
# prefixes, except the most recently created entry for each prefix. The
# per-commit caches (e2e-go-, go-unit-, verify-) are saved on every push to
# main and are each gigabytes; without pruning they push the repository past
# its cache quota and GitHub evicts the small long-lived caches first.
#
#   GH_TOKEN=<token with actions:write> GITHUB_REPOSITORY=<owner/repo> \
#     REF=refs/heads/main .github/scripts/ci/prune-caches.sh <prefix>...

set -o errexit -o nounset -o pipefail

for prefix in "$@"; do
  # Newest first; keep the first entry, delete the rest.
  mapfile -t ids < <(gh cache list --repo "${GITHUB_REPOSITORY}" --ref "${REF}" \
    --key "${prefix}" --sort created_at --order desc --limit 100 --json id --jq '.[].id')
  echo "${prefix}: ${#ids[@]} entries on ${REF}"
  for id in "${ids[@]:1}"; do
    gh cache delete "${id}" --repo "${GITHUB_REPOSITORY}"
  done
done
