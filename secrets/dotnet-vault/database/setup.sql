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