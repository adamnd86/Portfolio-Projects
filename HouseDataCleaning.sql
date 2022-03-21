/*

This is a data cleaning project for a Nashville Housing database.

*/

------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM dbo.House

-- Standardize Date Format

SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM dbo.House

Update House
SET SaleDate = Convert(Date,SaleDate)

Alter Table House
Add SaleDateConverted Date;

Update House
Set SaleDateConverted = Convert(Date,SaleDate)

SELECT SaleDateConverted
FROM dbo.House

----------------------------------------------------------------------------------------------------------------------------------------

--Populate Property Address Data

SELECT *
FROM dbo.House
--WHERE PropertyAddress is null
order by ParcelId

-- Find NULL entries where there are redundant ParcelIds

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.House a
JOIN dbo.House b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

-- Populate the NULL entries

UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.House a
JOIN dbo.House b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null

----------------------------------------------------------------------------------------------------------------------------------------------

--Breaking Addresses into Individual Columns (Address, City, State)

SELECT PropertyAddress 
FROM dbo.House
--WHERE PropertyAddress is null
--order by ParcelId

-- Check how to split Address into separate columns

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) As Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) As Address

FROM dbo.House

-- Add a new Address column and populate it
Alter Table House
Add PropertySplitAddress Nvarchar(255);

Update House
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

-- Add a new City column and populate it
Alter Table House
Add PropertySplitCity Nvarchar(255);

Update House
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

--Check how to split the OwnerAddress

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.') ,3)
,PARSENAME(REPLACE(OwnerAddress,',','.') ,2)
,PARSENAME(REPLACE(OwnerAddress,',','.') ,1)
FROM dbo.House

-- Create and populate split owner addresses

Alter Table House
Add OwnerSplitAddress Nvarchar(255);

Update House
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.') ,3)

Alter Table House
Add OwnerSplitCity Nvarchar(255);

Update House
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.') ,2)

Alter Table House
Add OwnerSplitState Nvarchar(255);

Update House
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.') ,1)

SELECT *
FROM dbo.House

----------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in the "Sold as Vacant" field

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM dbo.House
GROUP BY SoldasVacant
Order By 2


SELECT SoldAsVacant
, Case When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM dbo.House

UPDATE House
SET SoldAsVacant = Case When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


---------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM dbo.house
--order by ParcelID
)
SELECT * 
FROM RowNumCTE
WHERE row_num> 1
Order By PropertyAddress
----------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Unused Columns

SELECT *
FROM dbo.House

Alter Table dbo.House
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table dbo.House
Drop Column SaleDate
