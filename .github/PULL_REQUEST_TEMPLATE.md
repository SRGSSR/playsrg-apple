
### Motivation and Context

> Why is this change required? What problem does it solve?

### Description

> Please describe the changes and how to test.

### Checklist

- The branch should be rebased onto the `develop` branch for whole tests with nighties, but it's not required.*
- The code followed the code style:
	-  [ ] `swiftlint` has run to ensure the *Swift* code style is valid.
	-  [ ] `rubocop -a` has run to ensure the *Ruby* code style is valid.
- [ ] Remote configuration properties have been properly documented (if relevant).
- [ ] The documentation has been updated (if relevant).
- [ ] Issues are linked to the PR, if any.

* The project uses Github merge queue feature, which rebases onto the `develop` branch before merging the PR. 
