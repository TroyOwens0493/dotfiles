# Upstream source

Repository: https://github.com/t3dotgg/tstack

Commit: `11e37a74d0a6868c121cd0910ab2b3bd9873b92a`

Path: `skills/full-send`

License: MIT (see [LICENSE](LICENSE)).

Local changes: replaced dependencies on the removed `file-pr` and `babysit-pr`
tstack skills with direct pull request and monitoring steps. When the parent is
an OpenAI GPT model, the `sol-loop` review uses Claude Opus instead of Sol.
