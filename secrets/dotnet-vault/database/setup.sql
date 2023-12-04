-- Copyright (c) HashiCorp, Inc.
-- SPDX-License-Identifier: MPL-2.0

CREATE DATABASE HashiCorp;
GO
USE HashiCorp;
GO
DROP TABLE IF EXISTS Projects;
GO
CREATE TABLE Projects(
  [Id] [varchar](50),
  [YearOfFirstCommit] int,
  [GitHubLink] [varchar](255)
);
GO