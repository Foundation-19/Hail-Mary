# Name
### rg

# Synopsis
generate readme docs the way I like

# Description
This generates readme docs man page-ish style. If there's a package.json in your
current working directory, it will use some of the values to generate the readme.

It uses the following for a template:

```
# Name
### {{module_name}}

# Synopsis
{{synopsis}}

# Description

# Example

# Install:
`npm install {{module_name}}`

# Test:
`npm test`
```

# Example
`rg
`
# Install:
`npm install rg -g`

#Motivation
I can type a few less things now. This is also an ok example of how streams and pipe
work for people who new to node.