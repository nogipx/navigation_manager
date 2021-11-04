## Sub-root duplication

### New sub-root is really new

Then just append it to the pages collection.

### New sub-root is the same with currently visible route

It means that currently visible route is sub-root and it has no children. So, you can:

- ignore push
- force append to pages collection (not recommended, it produces empty subtree)

### New sub-root is not the same with currently visible route

Then it is exists somewhere in pages collection. Here can be two cases:

1. New sub-root is same with root of latest sub-tree.
2. New sub-root is same with root of sub-tree which exists somewhere in pages collection, but this sub-tree is not latest.

For this cases you can:
| Latest sub-tree | Not latest sub-tree |
| ------ | ------ |
| ignore | ignore |
| reset children | make it visible |
| pop last child | make it visible and pop last child |
| append (create new sub-tree) | make it visible and reset children |
| - | append (create new sub-tree) |
