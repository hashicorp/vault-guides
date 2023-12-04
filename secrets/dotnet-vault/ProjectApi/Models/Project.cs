// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MPL-2.0

namespace ProjectApi.Models
{
  public class Project
  {
    public string Id { get; set; }
    public int YearOfFirstCommit { get; set; }
    public string GitHubLink { get; set; }
  }
}