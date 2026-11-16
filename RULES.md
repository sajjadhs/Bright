# Rules

These baseline standards apply to every project of this owner. Do not relax them without explicit owner approval.

1. **Clean architecture.** Keep layers separate (presentation / application / domain / infrastructure for backends; feature folders and small components for frontends). No god-files, no business logic in controllers, no database calls in UI components.
2. **Readable code.** Use descriptive names, small functions and single responsibility.
3. **Design patterns where they fit.** Use Repository, CQRS/Mediator, Result, Specification, Strategy and similar patterns when they help. Do not force them where simple code is enough.
4. **Comments.** Default to no comments. Add a comment only when the reason is not obvious, such as a hidden constraint or an intentional workaround.
5. **Swagger/OpenAPI** on every backend, with summaries and response types on every endpoint.
6. **Tests.** Unit tests for every API endpoint and integration tests where several components interact. For .NET, use NUnit with FluentAssertions and NSubstitute.
7. **Development plan first.** Write the plan before writing code for a feature.

## Repository conventions

- The default branch is `master`.
- Commits use the owner's git identity. Commits never name Claude as author, committer or co-author.
- Private repositories have no LICENSE file.
