# Overview of Problem
Internally in RSpec-Core, when initializing an `Example`, an `ExampleHash` is created.
Within this creation process, the parent `ExampleGroup`'s metadata (which is a Ruby hash) is copied down to the child's metadata.

For initializing an `ExampleGroup`, an `ExampleGroupHash` is created. This seems to create a new Hash, but again keeps the parent example group's metadata.

You can find a direct link to the source code [here](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/metadata.rb#L214).

However, because only a shallow copy is done on the metadata, this is a problem. If there happen to be any nested hashes in the metadata, these references are carried down.

This problem was brought to our attention whilst using the [rspec_api_documentation](https://github.com/zipmark/rspec_api_documentation) gem.
The gem uses RSpec's metadata to save header information for acceptance tests. In doing so, [this helper method](https://github.com/zipmark/rspec_api_documentation/blob/master/lib/rspec_api_documentation/dsl/endpoint.rb#L75) creates a nested hash in the metadata.

(This example specifically adds a `:headers` hash, but the problem is not limited to this hash, but all nested hashes.) 

### External Source
[This article](https://blog.polleverywhere.com/shared-contexts-rspec/#:~:text=the%20metadata%20keys%20are%20shared%20globally.%20If%20two%20different%20shared%20contexts%20use%20the%20same%20metadata%20key%20and%20define%20the%20same%20let%2C%20for%20example%2C%20as%20two%20different%20values%2C%20then%20the%20actual%20value%20of%20that%20let%20will%20depend%20on%20the%20order%20of%20execution.)
on shared contexts talks about problems with metadata keys being shared globally. 

> However, it has one big drawback: the metadata keys are shared globally. If two different shared contexts use the same metadata key and define the same let, for example, as two different values, then the actual value of that let will depend on the order of execution.

Although the quote discusses lets, it applies for any usage of metadata.

**Furthermore, the article states this leakage behaviour as though it is intended, but I want to confirm before settling and making measures around it.**

***

I've written up a simple spec that demonstrates this problem. You can find it under `spec/example_spec.rb` (and `spec/example_spec_two.rb`), but I will also describe some points here.

Run it simply with `rspec spec/example_spec.rb` from the root directory.

I recommend reading the below steps alongside the example spec.

## Repro Steps
- A user-defined metadata has to be attached to an example group. This will affect any example groups or examples that are nested to it.
  - Make sure the attached metadata has a nested hash. This is what causes the leakage, due to the shallow copy.
  - In the example spec, I attach the following nested hash `:headers => { :top => 'create hash here' }` in a describe block.
- In any nested example group or example, add attributes to the nested hash.
  - In the example spec, this is done via the `set_header` defined in `spec_helper`.
- At this point, since all the nested example groups and examples share the same **reference** to the nested hash (`example.metadata[:headers]`), any items added to this hash will affect other metadata.

## Potential Solution
The proposed solution is simple - do a deep copy instead of a shallow copy when copying the parent example group metadata.
The shallow copy done for `ExampleHash` can be found [here](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/metadata.rb#L215). 

Upon refactoring the code to do a deep copy (after [line 219](https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/metadata.rb#L219) `group_metadata.update(example_metadata`), I was able to pass my spec.

# Conclusion
As stated earlier, I don't know for sure what the intended behaviour of the metadata is; whether it should be globally shared or not. 
But in the chance that it is a bug, I hope this will speed up any investigation necessary to fix it.

***

# References

https://relishapp.com/rspec/rspec-core/docs/metadata/user-defined-metadata

https://relishapp.com/rspec/rspec-core/docs/metadata/current-example

https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-context
https://blog.polleverywhere.com/shared-contexts-rspec/ (Has a section on this metadata leakage problem)
